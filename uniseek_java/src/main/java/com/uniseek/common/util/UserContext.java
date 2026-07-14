package com.uniseek.common.util;

/**
 * 用户上下文 —— 通过 ThreadLocal 存储当前请求的用户信息
 */
public class UserContext {

    private static final ThreadLocal<Long> userIdHolder = new ThreadLocal<>();
    private static final ThreadLocal<Integer> roleHolder = new ThreadLocal<>();

    /**
     * 设置当前用户信息
     */
    public static void set(Long userId, Integer role) {
        userIdHolder.set(userId);
        roleHolder.set(role);
    }

    /**
     * 获取当前用户 ID
     */
    public static Long getUserId() {
        return userIdHolder.get();
    }

    /**
     * 获取当前用户角色
     */
    public static Integer getRole() {
        return roleHolder.get();
    }

    /**
     * 清理当前用户信息（在请求结束时调用）
     */
    public static void clear() {
        userIdHolder.remove();
        roleHolder.remove();
    }
}
