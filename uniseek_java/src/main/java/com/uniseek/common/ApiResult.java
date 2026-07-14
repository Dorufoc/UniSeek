package com.uniseek.common;

/**
 * 统一响应结果封装
 *
 * @param <T> 数据类型
 */
public class ApiResult<T> {

    /** 成功 */
    public static final int SUCCESS = 200;
    /** 错误请求 */
    public static final int BAD_REQUEST = 400;
    /** 未授权 */
    public static final int UNAUTHORIZED = 401;
    /** 禁止访问 */
    public static final int FORBIDDEN = 403;
    /** 未找到 */
    public static final int NOT_FOUND = 404;
    /** 冲突 */
    public static final int CONFLICT = 409;
    /** 服务器内部错误 */
    public static final int INTERNAL_ERROR = 500;

    /** 状态码 */
    private int code;
    /** 消息 */
    private String message;
    /** 数据 */
    private T data;

    public ApiResult() {
    }

    public ApiResult(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    /**
     * 成功响应（默认成功消息）
     */
    public static <T> ApiResult<T> success(T data) {
        return new ApiResult<>(SUCCESS, "操作成功", data);
    }

    /**
     * 成功响应（自定义消息）
     */
    public static <T> ApiResult<T> success(String message, T data) {
        return new ApiResult<>(SUCCESS, message, data);
    }

    /**
     * 失败响应
     */
    public static <T> ApiResult<T> error(int code, String message) {
        return new ApiResult<>(code, message, null);
    }

    // ------ getters / setters ------

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }
}
