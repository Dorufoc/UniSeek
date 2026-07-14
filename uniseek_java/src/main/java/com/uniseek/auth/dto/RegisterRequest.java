package com.uniseek.auth.dto;

import lombok.Data;

import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Max;
import javax.validation.constraints.Min;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * 注册请求 DTO
 */
@Data
public class RegisterRequest {

    /** 手机号（11 位数字，1 开头） */
    @NotBlank(message = "手机号不能为空")
    @Pattern(regexp = "^1\\d{10}$", message = "手机号格式不正确")
    private String phone;

    /** 邮箱 */
    @NotBlank(message = "邮箱不能为空")
    @Email(message = "邮箱格式不正确")
    private String email;

    /** 密码（6~20 位） */
    @NotBlank(message = "密码不能为空")
    @Size(min = 6, max = 20, message = "密码长度需为 6~20 位")
    private String password;

    /** 确认密码 */
    @NotBlank(message = "确认密码不能为空")
    private String confirmPassword;

    /** 用户昵称（1~20 位） */
    @NotBlank(message = "昵称不能为空")
    @Size(min = 1, max = 20, message = "昵称长度需为 1~20 位")
    private String nickname;

    /** 角色：0 求职者 / 1 企业 HR（注册时不可选 9 管理员或 99 超级管理员） */
    @NotNull(message = "角色不能为空")
    @Min(0)
    @Max(1)
    private Integer role;
}
