package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 用户实体
 */
@Data
@TableName("user")
public class User {

    /** 用户 ID */
    @TableId
    private Long id;

    /** 手机号 */
    private String phone;

    /** 邮箱 */
    private String email;

    /** 密码（加密后） */
    private String password;

    /** 盐值 */
    private String salt;

    /** 用户昵称 */
    private String nickname;

    /** 头像 URL */
    private String avatarUrl;

    /** 角色：0-求职者, 1-企业HR, 9-管理员, 99-超级管理员 */
    private Integer role;

    /** 信用分，默认 100 */
    private Integer creditScore;

    /** 状态：0 禁用 / 1 正常，默认 1 */
    private Integer status;

    /** 实名认证状态（非数据库字段，查询时动态填充） */
    @TableField(exist = false)
    private Boolean realNameAuth;

    /** 最后登录时间 */
    private LocalDateTime lastLoginTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
