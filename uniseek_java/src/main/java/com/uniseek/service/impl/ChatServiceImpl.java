package com.uniseek.service.impl;

import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ChatMessageMapper;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.dto.SendMessageRequest;
import com.uniseek.entity.ChatMessage;
import com.uniseek.entity.ChatSession;
import com.uniseek.entity.Task;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import com.uniseek.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * 聊天服务实现
 */
@Service
public class ChatServiceImpl implements ChatService {

    @Autowired
    private ChatSessionMapper chatSessionMapper;

    @Autowired
    private ChatMessageMapper chatMessageMapper;

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private UserMapper userMapper;

    @Override
    public List<ChatSessionVO> getSessions(Long userId, Integer role) {
        List<ChatSessionVO> sessions;
        if (role == 1) {
            // HR：查看本企业相关会话
            sessions = chatSessionMapper.selectSessionsByEmployer(userId);
        } else {
            // 求职者：查看自己的会话
            sessions = chatSessionMapper.selectSessionsBySeeker(userId);
        }
        return sessions != null ? sessions : Collections.emptyList();
    }

    @Override
    public List<ChatMessageVO> getMessages(Long applicationId, Long userId, Integer role,
                                           Long beforeId, int pageSize) {
        // 1. 权限校验
        ChatSession session = validateSessionAccess(applicationId, userId, role);

        // 2. 自动标记对方消息为已读
        Long sessionId = session.getId();
        chatMessageMapper.markAsRead(sessionId, userId);

        // 3. 查询消息
        List<ChatMessage> messages;
        if (beforeId == null || beforeId <= 0) {
            // 首次加载，取最新 pageSize 条
            messages = chatMessageMapper.selectLatestMessages(sessionId, pageSize);
        } else {
            // 游标分页，取小于 beforeId 的 pageSize 条
            messages = chatMessageMapper.selectMessagesBeforeId(sessionId, beforeId, pageSize);
        }

        if (messages == null || messages.isEmpty()) {
            return Collections.emptyList();
        }

        // 4. 反转列表（DB 按 id 降序返回，转为升序便于前端展示）
        Collections.reverse(messages);

        // 5. 组装 VO（批量查询发送者信息）
        List<ChatMessageVO> voList = new ArrayList<>(messages.size());
        for (ChatMessage msg : messages) {
            ChatMessageVO vo = buildChatMessageVO(msg);
            voList.add(vo);
        }
        return voList;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public ChatMessageVO sendMessage(Long applicationId, Long userId, Integer role,
                                     SendMessageRequest request) {
        // 1. 权限校验
        ChatSession session = validateSessionAccess(applicationId, userId, role);

        // 2. 校验消息类型
        Integer messageType = request.getMessageType();
        if (messageType == null) {
            messageType = 0;
        }
        if (messageType != 0 && messageType != 1) {
            throw new BusinessException("消息类型不合法：0 文本 / 1 图片");
        }

        // 3. 插入消息
        Long sessionId = session.getId();
        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSessionId(sessionId);
        chatMessage.setSenderId(userId);
        chatMessage.setMessageType(messageType);
        chatMessage.setContent(request.getContent());
        chatMessage.setIsRead(0);
        chatMessage.setSendTime(LocalDateTime.now());
        chatMessageMapper.insert(chatMessage);

        // 4. 更新会话的最后消息
        session.setLastMessage(request.getContent());
        session.setLastMessageTime(chatMessage.getSendTime());
        session.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.updateById(session);

        // 5. 返回 VO
        return buildChatMessageVO(chatMessage);
    }

    @Override
    public ChatSessionVO getSessionDetail(Long applicationId, Long userId, Integer role) {
        ChatSessionVO vo = chatSessionMapper.selectSessionDetail(applicationId, userId, role);
        if (vo == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }
        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markSessionRead(Long applicationId, Long userId) {
        // 1. 查询会话 ID
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 2. 标记对方消息为已读
        chatMessageMapper.markAsRead(sessionId, userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createChatSession(Long applicationId, Long employerId, Long seekerId) {
        // 检查是否已存在会话
        Long existingId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (existingId != null) {
            return; // 已存在，不重复创建
        }

        ChatSession chatSession = new ChatSession();
        chatSession.setTaskApplicationId(applicationId);
        chatSession.setEmployerId(employerId);
        chatSession.setSeekerId(seekerId);
        chatSession.setStatus(0);
        chatSession.setCreateTime(LocalDateTime.now());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.insert(chatSession);
    }

    /**
     * 校验当前用户是否有权访问该会话
     *
     * @param applicationId 投递记录 ID
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @return 会话实体
     */
    private ChatSession validateSessionAccess(Long applicationId, Long userId, Integer role) {
        // 1. 查询投递记录
        TaskApplication application = taskApplicationMapper.selectById(applicationId);
        if (application == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
        }

        // 2. 查询会话
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }
        ChatSession session = chatSessionMapper.selectById(sessionId);
        if (session == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 3. 权限校验
        if (role == 1) {
            // HR：必须是该职位所属企业的 HR
            Task task = taskMapper.selectById(application.getTaskId());
            if (task == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "关联职位不存在");
            }
            // 校验当前用户是否是该企业的 HR
            com.uniseek.entity.Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
            if (enterprise == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "企业信息不存在");
            }
            if (!enterprise.getUserId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
        } else {
            // 求职者：必须是该会话的 seeker
            if (!session.getSeekerId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
        }

        return session;
    }

    /**
     * 构建 ChatMessageVO
     *
     * @param msg 消息实体
     * @return 消息 VO
     */
    private ChatMessageVO buildChatMessageVO(ChatMessage msg) {
        ChatMessageVO vo = new ChatMessageVO();
        vo.setId(msg.getId());
        vo.setSenderId(msg.getSenderId());
        vo.setMessageType(msg.getMessageType());
        vo.setContent(msg.getContent());
        vo.setIsRead(msg.getIsRead());
        vo.setSendTime(msg.getSendTime());

        // 查询发送者信息
        User sender = userMapper.selectById(msg.getSenderId());
        if (sender != null) {
            vo.setSenderName(sender.getNickname());
            vo.setSenderAvatar(sender.getAvatarUrl());
        }
        return vo;
    }
}