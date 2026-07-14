package com.uniseek.auth.dto;

import lombok.Data;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;

/**
 * 修改手机号请求 DTO
 */
@Data
public class UpdatePhoneRequest {

    @NotBlank(message = "新手机号不能为空")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String newPhone;

    /** 当前密码（验证身份） */
    @NotBlank(message = "密码不能为空")
    private String password;
}
