package com.uniseek.common.exception;

import com.uniseek.common.ApiResult;

/**
 * 业务异常，默认状态码 400
 */
public class BusinessException extends RuntimeException {

    private final int code;

    /**
     * 指定状态码和消息的业务异常
     */
    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    /**
     * 默认 400 状态码的业务异常
     */
    public BusinessException(String message) {
        super(message);
        this.code = ApiResult.BAD_REQUEST;
    }

    public int getCode() {
        return code;
    }
}
