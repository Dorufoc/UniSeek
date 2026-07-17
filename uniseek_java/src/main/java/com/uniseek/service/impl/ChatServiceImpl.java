package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ChatMessageMapper;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.ResumeMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.dto.SendMessageRequest;
import com.uniseek.entity.ChatMessage;
import com.uniseek.entity.ChatSession;
import com.uniseek.entity.Resume;
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

    @Autowired
    private ResumeMapper resumeMapper;

    @Override
    public List<ChatSessionVO> getSessions(Long userId, Integer role) {
        List<ChatSessionVO> sessions;
        if (role == 1) {
            sessions = chatSessionMapper.selectSessionsByEmployer(userId);
            List<ChatSessionVO> direct = chatSessionMapper.selectDirectSessionsByEmployer(userId);
            if (direct != null && !direct.isEmpty()) {
                if (sessions == null) sessions = direct;
                else sessions.addAll(direct);
            }
        } else {
            sessions = chatSessionMapper.selectSessionsBySeeker(userId);
            List<ChatSessionVO> direct = chatSessionMapper.selectDirectSessionsBySeeker(userId);
            if (direct != null && !direct.isEmpty()) {
                if (sessions == null) sessions = direct;
                else sessions.addAll(direct);
            }
        }
        // 合并职位投递会话与直接会话后，统一按最后消息时间倒序排序
        if (sessions != null) {
            sessions.sort((a, b) -> {
                LocalDateTime t1 = a.getLastMessageTime();
                LocalDateTime t2 = b.getLastMessageTime();
                if (t1 == null && t2 == null) return 0;
                if (t1 == null) return 1;
                if (t2 == null) return -1;
                return t2.compareTo(t1);
            });
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

        // DB 按 id 降序返回（最新在前），直接保留该顺序

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

        // 2. 求职者限制：HR 未回复前只能发送一条消息
        if (role == 0 && !computeCanSend(session, userId, role)) {
            throw new BusinessException("HR 未回复前，您只能发送一条消息");
        }

        // 3. 校验消息类型
        Integer messageType = request.getMessageType();
        if (messageType == null) {
            messageType = 0;
        }
        if (messageType == 2) {
            // 简历附件：仅求职者可发送，后端获取简历附件 URL
            if (role != 0) {
                throw new BusinessException("仅求职者可发送简历附件");
            }
            if (!session.getSeekerId().equals(userId)) {
                throw new BusinessException("无权发送简历");
            }
            String resumeUrl = getSeekerResumeUrl(userId);
            if (resumeUrl == null) {
                throw new BusinessException("暂无简历附件，请先上传简历文件");
            }
            request.setContent(resumeUrl);
        } else if (messageType != 0 && messageType != 1) {
            throw new BusinessException("消息类型不合法：0 文本 / 1 图片 / 2 简历附件");
        }

        // 4. 插入消息
        Long sessionId = session.getId();
        ChatMessage chatMessage = new ChatMessage();
        chatMessage.setSessionId(sessionId);
        chatMessage.setSenderId(userId);
        chatMessage.setMessageType(messageType);
        chatMessage.setContent(request.getContent());
        chatMessage.setIsRead(0);
        chatMessage.setSendTime(LocalDateTime.now());
        chatMessageMapper.insert(chatMessage);

        // 5. 更新会话的最后消息
        String preview;
        if (messageType == 2) {
            preview = "[简历附件]";
        } else if (messageType == 1) {
            preview = "[图片]";
        } else {
            preview = request.getContent();
        }
        session.setLastMessage(preview);
        session.setLastMessageTime(chatMessage.getSendTime());
        session.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.updateById(session);

        // 6. 返回 VO
        return buildChatMessageVO(chatMessage);
    }

    @Override
    public ChatSessionVO getSessionDetail(Long applicationId, Long userId, Integer role) {
        // 直接会话：applicationId = 0 或 applicationId = sessionId
        boolean isDirect = (applicationId != null && applicationId != 0
                && chatSessionMapper.selectIdByApplicationId(applicationId) == null);
        if (isDirect) {
            // 用 sessionId 查直接会话
            ChatSession session = chatSessionMapper.selectById(applicationId);
            if (session == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
            }
            if (role == 1 && !session.getEmployerId().equals(userId) ||
                role == 0 && !session.getSeekerId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
            // 查询对方用户信息
            Long counterpartId = role == 1 ? session.getSeekerId() : session.getEmployerId();
            User user = userMapper.selectById(counterpartId);
            ChatSessionVO vo = new ChatSessionVO();
            vo.setApplicationId(applicationId);
            vo.setCounterpartId(counterpartId);
            vo.setCounterpartName(user != null ? user.getNickname() : "未知用户");
            vo.setCounterpartAvatar(user != null ? user.getAvatarUrl() : null);
            vo.setLastMessage(session.getLastMessage());
            vo.setLastMessageTime(session.getLastMessageTime());
            vo.setUnreadCount(0);
            vo.setCanSend(true);
            return vo;
        }

        ChatSessionVO vo = chatSessionMapper.selectSessionDetail(applicationId, userId, role);
        if (vo == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }
        // 计算当前用户是否允许继续发送消息
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId != null) {
            ChatSession session = chatSessionMapper.selectById(sessionId);
            if (session != null) {
                vo.setCanSend(computeCanSend(session, userId, role));
            }
        }
        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markSessionRead(Long applicationId, Long userId) {
        // 1. 查询会话 ID（直接会话用 applicationId 作为 sessionId）
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId == null) {
            sessionId = applicationId;
        }
        ChatSession session = chatSessionMapper.selectById(sessionId);
        if (session == null) {
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

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createDirectSession(Long employerId, Long seekerId) {
        // 检查是否已存在直接会话
        Long existingId = chatSessionMapper.selectDirectSessionId(employerId, seekerId);
        if (existingId != null) {
            return existingId;
        }

        ChatSession chatSession = new ChatSession();
        chatSession.setTaskApplicationId(null);
        chatSession.setEmployerId(employerId);
        chatSession.setSeekerId(seekerId);
        chatSession.setStatus(0);
        chatSession.setCreateTime(LocalDateTime.now());
        chatSession.setUpdateTime(LocalDateTime.now());
        chatSessionMapper.insert(chatSession);
        return chatSession.getId();
    }

    /**
     * 计算当前用户是否允许在当前会话中发送消息
     * <p>HR  unrestricted；求职者仅在「未发送过消息」或「HR 已回复」时可发送。</p>
     *
     * @param session 会话实体
     * @param userId  当前用户 ID
     * @param role    当前用户角色
     * @return true 允许发送
     */
    private boolean computeCanSend(ChatSession session, Long userId, Integer role) {
        // HR 不受限制
        if (role == 1) {
            return true;
        }
        // 求职者：必须先属于该会话
        if (!session.getSeekerId().equals(userId)) {
            return false;
        }
        Long sessionId = session.getId();
        Long employerId = session.getEmployerId();

        // 统计求职者已发送的消息数
        long seekerMsgCount = chatMessageMapper.selectCount(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getSessionId, sessionId)
                        .eq(ChatMessage::getSenderId, userId));
        // 未发送过消息，允许发送第一条
        if (seekerMsgCount == 0) {
            return true;
        }
        // 已发送过消息，需等待 HR 回复后才能继续发送
        long employerMsgCount = chatMessageMapper.selectCount(
                new LambdaQueryWrapper<ChatMessage>()
                        .eq(ChatMessage::getSessionId, sessionId)
                        .eq(ChatMessage::getSenderId, employerId));
        return employerMsgCount > 0;
    }

    /**
     * 校验当前用户是否有权访问该会话
     *
     * @param applicationId 投递记录 ID（直接会话传 session ID）
     * @param userId        当前用户 ID
     * @param role          当前用户角色
     * @return 会话实体
     */
    private ChatSession validateSessionAccess(Long applicationId, Long userId, Integer role) {
        if (applicationId == null || applicationId == 0) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 区分直接会话（task_application_id IS NULL）与职位投递会话
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        boolean isDirect = (sessionId == null);

        if (isDirect) {
            // 直接会话：applicationId 就是 sessionId
            sessionId = applicationId;
        }
        ChatSession session = chatSessionMapper.selectById(sessionId);
        if (session == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "会话不存在");
        }

        // 权限校验
        if (isDirect) {
            // 直接会话：仅校验 employer/seeker 匹配
            if (role == 1 && !session.getEmployerId().equals(userId) ||
                role == 0 && !session.getSeekerId().equals(userId)) {
                throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
            }
        } else {
            // 职位投递会话：沿用原有校验（查投递记录 → 职位 → 企业）
            TaskApplication application = taskApplicationMapper.selectById(applicationId);
            if (application == null) {
                throw new BusinessException(ApiResult.NOT_FOUND, "投递记录不存在");
            }
            if (role == 1) {
                Task task = taskMapper.selectById(application.getTaskId());
                if (task == null) {
                    throw new BusinessException(ApiResult.NOT_FOUND, "关联职位不存在");
                }
                com.uniseek.entity.Enterprise enterprise = enterpriseMapper.selectById(task.getEnterpriseId());
                if (enterprise == null) {
                    throw new BusinessException(ApiResult.NOT_FOUND, "企业信息不存在");
                }
                if (!enterprise.getUserId().equals(userId)) {
                    throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
                }
            } else {
                if (!session.getSeekerId().equals(userId)) {
                    throw new BusinessException(ApiResult.FORBIDDEN, "无权访问该会话");
                }
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

    /**
     * 获取求职者的简历附件 URL
     */
    private String getSeekerResumeUrl(Long seekerId) {
        Resume resume = resumeMapper.selectOne(
                new LambdaQueryWrapper<Resume>().eq(Resume::getUserId, seekerId));
        return resume != null ? resume.getAttachmentUrl() : null;
    }
}