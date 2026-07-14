package com.uniseek.common.exception;

import com.uniseek.common.ApiResult;

/**
 * 未授权异常，状态码 401
 */
public class UnauthorizedException extends RuntimeException {

    private final int code;

    public UnauthorizedException(String message) {
        super(message);
        this.code = ApiResult.UNAUTHORIZED;
    }

    public int getCode() {
        return code;
    }
}
