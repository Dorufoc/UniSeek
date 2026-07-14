package com.uniseek.auth.dto;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户信息 VO（脱敏后返回给前端）
 */
@Data
public class UserVO {

    /** 用户 ID */
    private Long id;

    /** 手机号（脱敏格式：138****8000） */
    private String phone;

    /** 邮箱（脱敏格式：zha***@example.com） */
    private String email;

    /** 用户昵称 */
    private String nickname;

    /** 头像 URL */
    private String avatarUrl;

    /** 角色：0 求职者 / 1 企业 HR / 9 管理员 / 99 超级管理员 */
    private Integer role;

    /** 状态：0 禁用 / 1 正常 */
    private Integer status;

    /** 信用分 */
    private Integer creditScore;

    /** 最后登录时间 */
    private LocalDateTime lastLoginTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /**
     * 手机号脱敏：保留前 3 位和后 4 位，中间用 **** 代替
     *
     * @param phone 原始手机号
     * @return 脱敏后的手机号，如 138****8000
     */
    public static String phoneDesensitization(String phone) {
        if (phone == null || phone.length() < 7) {
            return phone;
        }
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    /**
     * 邮箱脱敏：@ 符号前面保留前 3 个字符 + ***
     *
     * @param email 原始邮箱
     * @return 脱敏后的邮箱，如 zha***@example.com
     */
    public static String emailDesensitization(String email) {
        if (email == null || !email.contains("@")) {
            return email;
        }
        String[] parts = email.split("@");
        String name = parts[0];
        String domain = parts[1];
        if (name.length() <= 3) {
            return name + "***@" + domain;
        }
        return name.substring(0, 3) + "***@" + domain;
    }
}
