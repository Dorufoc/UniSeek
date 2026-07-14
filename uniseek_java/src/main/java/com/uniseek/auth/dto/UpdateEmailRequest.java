package com.uniseek.auth.dto;

import lombok.Data;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;

/**
 * 修改邮箱请求 DTO
 */
@Data
public class UpdateEmailRequest {

    @NotBlank(message = "新邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String newEmail;

    /** 当前密码（验证身份） */
    @NotBlank(message = "密码不能为空")
    private String password;
}
