package com.uniseek.auth.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * 修改密码请求 DTO
 */
@Data
public class ChangePasswordRequest {

    /** 原密码 */
    @NotBlank(message = "原密码不能为空")
    private String oldPassword;

    /** 新密码（6~20 位） */
    @NotBlank(message = "新密码不能为空")
    @Size(min = 6, max = 20, message = "新密码长度需为 6~20 位")
    private String newPassword;

    /** 确认新密码 */
    @NotBlank(message = "确认密码不能为空")
    private String confirmPassword;
}
