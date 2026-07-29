package com.uniseek.chat;

/**
 * 聊天会话类型判别器
 * <p>
 * 用于区分职位投递会话（application）与直接会话（direct），
 * 避免 chat_session.id 与 task_application.id 发生数值重叠时解析错乱。
 * </p>
 */
public final class ChatSessionType {

    /** 职位投递会话：通过 task_application_id 关联 chat_session */
    public static final String APPLICATION = "application";

    /** 直接会话：chat_session.id 本身就是会话主键，无投递记录关联 */
    public static final String DIRECT = "direct";

    private ChatSessionType() {
    }

    /**
     * 判断是否为直接会话
     *
     * @param sessionType 前端传入的会话类型
     * @return true 表示直接会话
     */
    public static boolean isDirect(String sessionType) {
        return DIRECT.equalsIgnoreCase(sessionType);
    }

    /**
     * 判断是否为投递会话（未传时默认兼容旧版投递会话）
     *
     * @param sessionType 前端传入的会话类型
     * @return true 表示投递会话或缺省值
     */
    public static boolean isApplication(String sessionType) {
        return sessionType == null || APPLICATION.equalsIgnoreCase(sessionType);
    }
}
