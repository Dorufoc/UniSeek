package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 简历实体
 */
@Data
@TableName("resume")
public class Resume {

    /** 简历 ID */
    @TableId
    private Long id;

    /** 用户 ID */
    private Long userId;

    /** 性别：0 男 / 1 女 */
    private Integer gender;

    /** 出生日期 */
    private LocalDate birthDate;

    /** 最高学历 */
    private String education;

    /** 毕业院校 */
    private String school;

    /** 技能特长 */
    private String skills;

    /** 工作经历 */
    private String experience;

    /** 附件简历 URL */
    private String attachmentUrl;

    /** 是否已发布到人才市场：0 未发布 / 1 已发布 */
    private Integer isPublished;

    /** 真实姓名（来自 real_name_auth 表 JOIN 查询，非数据库字段） */
    @TableField(exist = false)
    private String realName;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}