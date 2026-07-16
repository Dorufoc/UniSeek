package com.uniseek.controller;

import com.uniseek.chat.websocket.ChatWebSocketHandler;
import com.uniseek.common.ApiResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.ChatSessionVO;
import com.uniseek.dto.SendMessageRequest;
import com.uniseek.entity.ChatSession;
import com.uniseek.service.ChatService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 聊天控制器
 */
@RestController
@RequestMapping("/api/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    @Autowired
    private ChatWebSocketHandler chatWebSocketHandler;

    @Autowired
    private ChatSessionMapper chatSessionMapper;

    /**
     * 获取聊天会话列表
     * GET /api/chat/sessions
     *
     * @return 会话列表
     */
    @GetMapping("/sessions")
    public ApiResult<List<ChatSessionVO>> getSessions() {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        List<ChatSessionVO> sessions = chatService.getSessions(userId, role);
        return ApiResult.success(sessions);
    }

    /**
     * 获取会话详情
     * GET /api/chat/sessions/{applicationId}
     *
     * @param applicationId 投递记录 ID
     * @return 会话详情
     */
    @GetMapping("/sessions/{applicationId}")
    public ApiResult<ChatSessionVO> getSessionDetail(@PathVariable Long applicationId) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        ChatSessionVO vo = chatService.getSessionDetail(applicationId, userId, role);
        return ApiResult.success(vo);
    }

    /**
     * 加载聊天历史消息（游标分页）
     * GET /api/chat/sessions/{applicationId}/messages?beforeId=&pageSize=
     *
     * @param applicationId 投递记录 ID
     * @param beforeId      游标 ID（首次加载传空）
     * @param pageSize      每页条数（默认 20）
     * @return 历史消息列表（按发送时间升序）
     */
    @GetMapping("/sessions/{applicationId}/messages")
    public ApiResult<List<ChatMessageVO>> getMessages(
            @PathVariable Long applicationId,
            @RequestParam(required = false) Long beforeId,
            @RequestParam(defaultValue = "20") int pageSize) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        if (pageSize < 1 || pageSize > 100) {
            pageSize = 20;
        }
        List<ChatMessageVO> messages = chatService.getMessages(applicationId, userId, role, beforeId, pageSize);
        return ApiResult.success(messages);
    }

    /**
     * 发送消息
     * POST /api/chat/sessions/{applicationId}/messages
     *
     * @param applicationId 投递记录 ID（直接会话传 session ID）
     * @param request       发送消息请求
     * @return 发送的消息
     */
    @PostMapping("/sessions/{applicationId}/messages")
    public ApiResult<ChatMessageVO> sendMessage(
            @PathVariable Long applicationId,
            @Valid @RequestBody SendMessageRequest request) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        ChatMessageVO vo = chatService.sendMessage(applicationId, userId, role, request);

        // 查询会话并获取接收方
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId == null) {
            sessionId = applicationId; // 直接会话：applicationId 就是 sessionId
        }
        ChatSession session = chatSessionMapper.selectById(sessionId);
        if (session != null) {
            Long receiverId = userId.equals(session.getEmployerId())
                    ? session.getSeekerId()
                    : session.getEmployerId();
            chatWebSocketHandler.notifyNewMessage(receiverId, vo, applicationId);
        }

        return ApiResult.success("发送成功", vo);
    }

    /**
     * 创建直接会话（人才库联系求职者）
     * POST /api/chat/sessions/direct
     *
     * @param targetUserId 目标用户 ID（求职者）
     * @return 会话 ID
     */
    @PostMapping("/sessions/direct")
    public ApiResult<Long> createDirectSession(@RequestParam Long targetUserId) {
        Long userId = UserContext.getUserId();
        Long sessionId = chatService.createDirectSession(userId, targetUserId);
        return ApiResult.success(sessionId);
    }

    /**
     * 标记会话已读
     * PUT /api/chat/sessions/{applicationId}/read
     *
     * @param applicationId 投递记录 ID
     * @return 操作结果
     */
    @PutMapping("/sessions/{applicationId}/read")
    public ApiResult<Void> markSessionRead(@PathVariable Long applicationId) {
        Long userId = UserContext.getUserId();
        chatService.markSessionRead(applicationId, userId);
        return ApiResult.success(null);
    }
}
