package com.uniseek.chat.websocket;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.ChatSessionMapper;
import com.uniseek.dto.ChatMessageVO;
import com.uniseek.dto.SendMessageRequest;
import com.uniseek.entity.ChatSession;
import com.uniseek.service.ChatService;
import com.uniseek.util.JwtUtil;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.io.IOException;
import java.net.URI;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArraySet;

/**
 * WebSocket 聊天消息处理器
 * <p>
 * 基于原生 Spring WebSocket（非 STOMP），通过 URI 查询参数携带 Token 进行鉴权，
 * 使用 ConcurrentHashMap 维护 userId → WebSocketSession 的连接池，
 * 支持消息发送、已读回执、心跳检测等功能。
 * </p>
 *
 * <h3>消息格式（统一 JSON 帧）</h3>
 * <pre>
 * {"type": "EVENT_TYPE", "data": {...}, "timestamp": "yyyy-MM-dd HH:mm:ss"}
 * </pre>
 *
 * <h3>事件类型</h3>
 * <ul>
 *   <li><b>SEND_MESSAGE</b>（客户端→服务端）：发送消息</li>
 *   <li><b>READ_RECEIPT</b>（客户端→服务端）：已读回执</li>
 *   <li><b>PING</b>（客户端→服务端）：心跳检测</li>
 *   <li><b>NEW_MESSAGE</b>（服务端→接收方）：新消息推送</li>
 *   <li><b>MESSAGE_READ</b>（服务端→发送方）：消息已读通知</li>
 *   <li><b>SEND_ACK</b>（服务端→发送方）：消息发送确认</li>
 *   <li><b>ERROR</b>（服务端→客户端）：错误信息</li>
 *   <li><b>PONG</b>（服务端→客户端）：心跳回复</li>
 * </ul>
 */
@Component
public class ChatWebSocketHandler extends TextWebSocketHandler {

    private static final Logger log = LoggerFactory.getLogger(ChatWebSocketHandler.class);
    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ChatService chatService;

    @Autowired
    private ChatSessionMapper chatSessionMapper;

    @Autowired
    private ObjectMapper objectMapper;

    /** 用户连接池：userId → Set<WebSocketSession>（线程安全） */
    private final ConcurrentHashMap<Long, Set<WebSocketSession>> userSessions = new ConcurrentHashMap<>();

    // ======================== 连接生命周期 ========================

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        try {
            // 1. 从 URI 查询参数中提取 Token
            String token = extractToken(session);
            if (token == null || token.isEmpty()) {
                sendMessageAndClose(session, buildError(4001, "缺少 token 参数"));
                return;
            }

            // 2. 验证 Token
            Claims claims;
            try {
                claims = jwtUtil.parseToken(token);
            } catch (Exception e) {
                sendMessageAndClose(session, buildError(4002, "Token 无效或已过期"));
                return;
            }

            // 3. 解析用户信息
            Long userId = claims.get("userId", Long.class);
            Integer role = claims.get("role", Integer.class);

            if (userId == null || role == null) {
                sendMessageAndClose(session, buildError(4003, "Token 载荷解析失败"));
                return;
            }

            // 4. 将认证信息存入会话属性
            session.getAttributes().put("userId", userId);
            session.getAttributes().put("role", role);

            // 5. 加入连接池
            addSession(userId, session);

            log.info("WebSocket 连接建立成功: userId={}, role={}, sessionId={}",
                    userId, role, session.getId());
        } catch (Exception e) {
            log.error("WebSocket 连接建立异常", e);
            closeSessionSilently(session);
        }
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        try {
            JsonNode root = objectMapper.readTree(message.getPayload());
            String type = root.has("type") ? root.get("type").asText("") : "";
            JsonNode data = root.has("data") ? root.get("data") : null;

            // 获取认证信息
            Long userId = (Long) session.getAttributes().get("userId");
            Integer role = (Integer) session.getAttributes().get("role");

            if (userId == null || role == null) {
                sendMessage(session, buildError(4010, "未认证的连接，请重新建立连接"));
                return;
            }

            switch (type) {
                case "SEND_MESSAGE":
                    handleSendMessage(session, userId, role, data);
                    break;
                case "READ_RECEIPT":
                    handleReadReceipt(session, userId, role, data);
                    break;
                case "PING":
                    handlePing(session);
                    break;
                default:
                    sendMessage(session, buildError(4004, "未知消息类型: " + type));
            }
        } catch (Exception e) {
            log.error("处理 WebSocket 消息异常: sessionId={}", session.getId(), e);
            sendMessage(session, buildError(5000, "消息处理异常，请重试"));
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        removeSession(session);
        Long userId = (Long) session.getAttributes().get("userId");
        log.info("WebSocket 连接已关闭: userId={}, sessionId={}, status={}",
                userId, session.getId(), status);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) {
        log.error("WebSocket 传输异常: sessionId={}", session.getId(), exception);
        removeSession(session);
        closeSessionSilently(session);
    }

    // ======================== 消息处理逻辑 ========================

    /**
     * 处理 SEND_MESSAGE 类型消息
     * <p>
     * 1. 调用 ChatService.sendMessage 存储消息
     * 2. 查询会话确定接收方
     * 3. 向接收方推送 NEW_MESSAGE 事件
     * 4. 向发送方回复 SEND_ACK 确认
     * </p>
     */
    private void handleSendMessage(WebSocketSession session, Long userId, Integer role, JsonNode data) {
        if (data == null) {
            sendMessage(session, buildError(4100, "缺少消息数据"));
            return;
        }

        Long applicationId = data.has("applicationId") ? data.get("applicationId").asLong() : null;
        Integer messageType = data.has("messageType") ? data.get("messageType").asInt() : 0;
        String content = data.has("content") ? data.get("content").asText("") : "";

        // 参数校验
        if (applicationId == null) {
            sendMessage(session, buildError(4101, "缺少 applicationId"));
            return;
        }
        if (content.isEmpty()) {
            sendMessage(session, buildError(4102, "消息内容不能为空"));
            return;
        }

        try {
            // 1. 调用 ChatService 存储消息
            SendMessageRequest request = new SendMessageRequest();
            request.setMessageType(messageType);
            request.setContent(content);
            ChatMessageVO msgVo = chatService.sendMessage(applicationId, userId, role, request);

            // 2. 查询会话确定接收方
            ChatSession chatSession = getChatSessionByApplicationId(applicationId);
            if (chatSession == null) {
                sendMessage(session, buildError(4103, "会话不存在"));
                return;
            }

            Long receiverId = userId.equals(chatSession.getEmployerId())
                    ? chatSession.getSeekerId()
                    : chatSession.getEmployerId();

            // 当前时间字符串
            String nowStr = LocalDateTime.now().format(DTF);

            // 3. 向接收方推送 NEW_MESSAGE 事件
            Map<String, Object> newMsgData = new HashMap<>();
            newMsgData.put("messageId", msgVo.getId());
            newMsgData.put("applicationId", applicationId);
            newMsgData.put("senderId", userId);
            newMsgData.put("senderName", msgVo.getSenderName());
            newMsgData.put("senderAvatar", msgVo.getSenderAvatar());
            newMsgData.put("content", content);
            newMsgData.put("messageType", messageType);
            newMsgData.put("sendTime", msgVo.getSendTime() != null
                    ? msgVo.getSendTime().format(DTF) : nowStr);
            broadcastToUser(receiverId, buildMessage("NEW_MESSAGE", newMsgData));

            // 4. 向发送方回复 ACK
            Map<String, Object> ackData = new HashMap<>();
            ackData.put("messageId", msgVo.getId());
            ackData.put("applicationId", applicationId);
            ackData.put("messageType", messageType);
            ackData.put("content", content);
            ackData.put("sendTime", msgVo.getSendTime() != null
                    ? msgVo.getSendTime().format(DTF) : nowStr);
            sendMessage(session, buildMessage("SEND_ACK", ackData));

        } catch (BusinessException e) {
            log.warn("发送消息业务异常: userId={}, applicationId={}, msg={}",
                    userId, applicationId, e.getMessage());
            sendMessage(session, buildError(4300, e.getMessage()));
        } catch (Exception e) {
            log.error("发送消息系统异常: userId={}, applicationId={}", userId, applicationId, e);
            sendMessage(session, buildError(5000, "发送消息失败，请稍后重试"));
        }
    }

    /**
     * 处理 READ_RECEIPT 类型消息
     * <p>
     * 1. 调用 ChatService.markSessionRead 标记已读
     * 2. 向消息发送方（对方）推送 MESSAGE_READ 事件
     * </p>
     */
    private void handleReadReceipt(WebSocketSession session, Long userId, Integer role, JsonNode data) {
        if (data == null) {
            sendMessage(session, buildError(4200, "缺少已读回执数据"));
            return;
        }

        Long applicationId = data.has("applicationId") ? data.get("applicationId").asLong() : null;
        Long lastReadMessageId = data.has("lastReadMessageId") ? data.get("lastReadMessageId").asLong() : null;

        if (applicationId == null) {
            sendMessage(session, buildError(4201, "缺少 applicationId"));
            return;
        }

        try {
            // 1. 标记已读
            chatService.markSessionRead(applicationId, userId);

            // 2. 查询会话确定消息发送方（对方用户）
            ChatSession chatSession = getChatSessionByApplicationId(applicationId);
            if (chatSession != null) {
                Long senderId = userId.equals(chatSession.getEmployerId())
                        ? chatSession.getSeekerId()
                        : chatSession.getEmployerId();

                // 3. 向消息发送方推送 MESSAGE_READ 事件（通知对方消息已被阅读）
                Map<String, Object> readData = new HashMap<>();
                readData.put("applicationId", applicationId);
                readData.put("readerId", userId);
                if (lastReadMessageId != null) {
                    readData.put("lastReadMessageId", lastReadMessageId);
                }
                broadcastToUser(senderId, buildMessage("MESSAGE_READ", readData));
            }
        } catch (BusinessException e) {
            log.warn("已读回执业务异常: userId={}, applicationId={}, msg={}",
                    userId, applicationId, e.getMessage());
            sendMessage(session, buildError(4301, e.getMessage()));
        } catch (Exception e) {
            log.error("已读回执处理异常: userId={}, applicationId={}", userId, applicationId, e);
            sendMessage(session, buildError(5000, "已读回执处理失败"));
        }
    }

    /**
     * 处理 PING 类型消息（心跳检测）
     */
    private void handlePing(WebSocketSession session) {
        sendMessage(session, buildMessage("PONG", new HashMap<>()));
    }

    // ======================== 连接池管理 ========================

    /**
     * 将用户会话加入连接池
     */
    private void addSession(Long userId, WebSocketSession session) {
        Set<WebSocketSession> sessions = userSessions.computeIfAbsent(userId, k -> new CopyOnWriteArraySet<>());
        sessions.add(session);
    }

    /**
     * 从连接池移除指定会话
     */
    private void removeSession(WebSocketSession session) {
        Long userId = (Long) session.getAttributes().get("userId");
        if (userId != null) {
            Set<WebSocketSession> sessions = userSessions.get(userId);
            if (sessions != null) {
                sessions.remove(session);
                if (sessions.isEmpty()) {
                    userSessions.remove(userId);
                }
            }
        }
    }

    /**
     * 提供给 Controller 使用的公开方法，推送给指定用户 NEW_MESSAGE 事件
     */
    public void notifyNewMessage(Long receiverId, ChatMessageVO msgVo, Long applicationId) {
        Map<String, Object> data = new HashMap<>();
        data.put("messageId", msgVo.getId());
        data.put("applicationId", applicationId);
        data.put("senderId", msgVo.getSenderId());
        data.put("senderName", msgVo.getSenderName());
        data.put("senderAvatar", msgVo.getSenderAvatar());
        data.put("content", msgVo.getContent());
        data.put("messageType", msgVo.getMessageType());
        data.put("sendTime", msgVo.getSendTime() != null
                ? msgVo.getSendTime().format(DTF) : LocalDateTime.now().format(DTF));
        broadcastToUser(receiverId, buildMessage("NEW_MESSAGE", data));
    }

    /**
     * 向指定用户的所有在线连接广播消息
     *
     * @param userId  目标用户 ID
     * @param message 待发送的 JSON 字符串
     */
    public void broadcastToUser(Long userId, String message) {
        Set<WebSocketSession> sessions = userSessions.get(userId);
        if (sessions == null || sessions.isEmpty()) {
            return;
        }
        TextMessage textMessage = new TextMessage(message);
        for (WebSocketSession session : sessions) {
            if (session.isOpen()) {
                try {
                    session.sendMessage(textMessage);
                } catch (IOException e) {
                    log.error("向用户推送消息失败: userId={}, sessionId={}",
                            userId, session.getId(), e);
                }
            }
        }
    }

    // ======================== 工具方法 ========================

    /**
     * 从 WebSocketSession 的 URI 中提取 token 查询参数
     */
    private String extractToken(WebSocketSession session) {
        URI uri = session.getUri();
        if (uri == null) {
            return null;
        }
        String query = uri.getQuery();
        if (query == null || query.isEmpty()) {
            return null;
        }
        for (String param : query.split("&")) {
            String[] pair = param.split("=", 2);
            if (pair.length == 2 && "token".equals(pair[0])) {
                return pair[1];
            }
        }
        return null;
    }

    /**
     * 根据 applicationId 查询 ChatSession（包含 employerId 和 seekerId）
     */
    private ChatSession getChatSessionByApplicationId(Long applicationId) {
        Long sessionId = chatSessionMapper.selectIdByApplicationId(applicationId);
        if (sessionId == null) {
            return null;
        }
        return chatSessionMapper.selectById(sessionId);
    }

    /**
     * 构建统一格式的 JSON 消息
     *
     * @param type 事件类型
     * @param data 消息数据
     * @return JSON 字符串
     */
    private String buildMessage(String type, Map<String, Object> data) {
        try {
            ObjectNode root = objectMapper.createObjectNode();
            root.put("type", type);
            root.set("data", objectMapper.valueToTree(data));
            root.put("timestamp", LocalDateTime.now().format(DTF));
            return objectMapper.writeValueAsString(root);
        } catch (Exception e) {
            log.error("构建消息 JSON 失败: type={}", type, e);
            return "{\"type\":\"ERROR\",\"data\":{\"code\":5001,\"message\":\"消息构建异常\"}}";
        }
    }

    /**
     * 构建错误消息
     *
     * @param code    错误码
     * @param message 错误描述
     * @return JSON 字符串
     */
    private String buildError(int code, String message) {
        Map<String, Object> errorData = new HashMap<>();
        errorData.put("code", code);
        errorData.put("message", message);
        return buildMessage("ERROR", errorData);
    }

    /**
     * 向客户端发送消息
     */
    private void sendMessage(WebSocketSession session, String message) {
        if (session != null && session.isOpen()) {
            try {
                session.sendMessage(new TextMessage(message));
            } catch (IOException e) {
                log.warn("发送消息失败: sessionId={}", session.getId(), e);
            }
        }
    }

    /**
     * 发送错误消息后关闭连接
     */
    private void sendMessageAndClose(WebSocketSession session, String message) {
        try {
            if (session.isOpen()) {
                session.sendMessage(new TextMessage(message));
            }
        } catch (IOException e) {
            log.warn("发送消息后关闭连接异常", e);
        } finally {
            closeSessionSilently(session);
        }
    }

    /**
     * 安全关闭会话（不抛异常）
     */
    private void closeSessionSilently(WebSocketSession session) {
        if (session != null && session.isOpen()) {
            try {
                session.close();
            } catch (IOException e) {
                // 忽略关闭时的异常
            }
        }
    }
}
