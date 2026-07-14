package com.uniseek.auth.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;

/**
 * 实名认证请求 DTO
 */
@Data
public class RealNameAuthRequest {

    /** 真实姓名 */
    @NotBlank(message = "真实姓名不能为空")
    private String realName;

    /** 身份证号 */
    @NotBlank(message = "身份证号不能为空")
    private String idCard;
}
