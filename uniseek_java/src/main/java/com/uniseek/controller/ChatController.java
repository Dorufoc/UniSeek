package com.uniseek.controller;

import com.uniseek.chat.ChatSessionType;
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
     * GET /api/chat/sessions/{sessionId}?sessionType=
     *
     * @param sessionId   会话标识：投递会话为 task_application_id，直接会话为 chat_session.id
     * @param sessionType 会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 会话详情
     */
    @GetMapping("/sessions/{sessionId}")
    public ApiResult<ChatSessionVO> getSessionDetail(@PathVariable Long sessionId,
                                                       @RequestParam(required = false) String sessionType) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        ChatSessionVO vo = chatService.getSessionDetail(sessionId, userId, role, sessionType);
        return ApiResult.success(vo);
    }

    /**
     * 加载聊天历史消息（游标分页）
     * GET /api/chat/sessions/{sessionId}/messages?beforeId=&pageSize=&sessionType=
     *
     * @param sessionId   会话标识：投递会话为 task_application_id，直接会话为 chat_session.id
     * @param beforeId    游标 ID（首次加载传空）
     * @param pageSize    每页条数（默认 20）
     * @param sessionType 会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 历史消息列表（按发送时间升序）
     */
    @GetMapping("/sessions/{sessionId}/messages")
    public ApiResult<List<ChatMessageVO>> getMessages(
            @PathVariable Long sessionId,
            @RequestParam(required = false) Long beforeId,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String sessionType) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        if (pageSize < 1 || pageSize > 100) {
            pageSize = 20;
        }
        List<ChatMessageVO> messages = chatService.getMessages(sessionId, userId, role, beforeId, pageSize, sessionType);
        return ApiResult.success(messages);
    }

    /**
     * 发送消息
     * POST /api/chat/sessions/{sessionId}/messages?sessionType=
     *
     * @param sessionId   会话标识：投递会话为 task_application_id，直接会话为 chat_session.id
     * @param request     发送消息请求
     * @param sessionType 会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 发送的消息
     */
    @PostMapping("/sessions/{sessionId}/messages")
    public ApiResult<ChatMessageVO> sendMessage(
            @PathVariable Long sessionId,
            @Valid @RequestBody SendMessageRequest request,
            @RequestParam(required = false) String sessionType) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        ChatMessageVO vo = chatService.sendMessage(sessionId, userId, role, request, sessionType);

        // 使用与服务层一致的 sessionType 会话解析规则，避免投递记录 ID 与会话主键重叠时取错会话。
        ChatSession session = resolveChatSession(sessionId, sessionType);
        if (session != null) {
            Long receiverId = userId.equals(session.getEmployerId())
                    ? session.getSeekerId()
                    : session.getEmployerId();
            chatWebSocketHandler.notifyNewMessage(receiverId, vo, sessionId, sessionType);
        }

        return ApiResult.success("发送成功", vo);
    }

    private ChatSession resolveChatSession(Long sessionId, String sessionType) {
        // 直接会话：sessionId 即 chat_session.id
        if (ChatSessionType.isDirect(sessionType)) {
            return chatSessionMapper.selectById(sessionId);
        }
        // 投递会话：通过 task_application_id 解析 chat_session.id
        Long chatSessionId = chatSessionMapper.selectIdByApplicationId(sessionId);
        if (chatSessionId != null) {
            return chatSessionMapper.selectById(chatSessionId);
        }
        return null;
    }

    /**
     * 创建直接会话（人才库联系求职者）
     * POST /api/chat/sessions/direct
     * <p>返回的 sessionId 为 chat_session.id，后续调用需配合 sessionType=direct</p>
     *
     * @param targetUserId 目标用户 ID（求职者）
     * @return 直接会话的 chat_session.id
     */
    @PostMapping("/sessions/direct")
    public ApiResult<Long> createDirectSession(@RequestParam Long targetUserId) {
        Long userId = UserContext.getUserId();
        Long sessionId = chatService.createDirectSession(userId, targetUserId);
        return ApiResult.success(sessionId);
    }

    /**
     * 标记会话已读
     * PUT /api/chat/sessions/{sessionId}/read?sessionType=
     *
     * @param sessionId   会话标识：投递会话为 task_application_id，直接会话为 chat_session.id
     * @param sessionType 会话类型：application 投递会话 / direct 直接会话；缺省按 application 兼容旧版
     * @return 操作结果
     */
    @PutMapping("/sessions/{sessionId}/read")
    public ApiResult<Void> markSessionRead(@PathVariable Long sessionId,
                                             @RequestParam(required = false) String sessionType) {
        Long userId = UserContext.getUserId();
        chatService.markSessionRead(sessionId, userId, sessionType);
        return ApiResult.success(null);
    }

    /**
     * 初始化（创建）投递记录的聊天会话
     * POST /api/chat/sessions/{applicationId}/init
     * <p>HR 在首页点击「联系」时调用，确保会话已就绪</p>
     *
     * @param applicationId 投递记录 ID
     * @return 操作结果
     */
    @PostMapping("/sessions/{applicationId}/init")
    public ApiResult<Void> initChatSession(@PathVariable Long applicationId) {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        chatService.initChatSession(applicationId, userId, role);
        return ApiResult.success(null);
    }

    /**
     * 获取当前用户所有会话的未读消息总数
     * GET /api/chat/unread-count
     */
    @GetMapping("/unread-count")
    public ApiResult<Long> getUnreadCount() {
        Long userId = UserContext.getUserId();
        Long count = chatService.getUnreadCount(userId);
        return ApiResult.success(count);
    }
}
