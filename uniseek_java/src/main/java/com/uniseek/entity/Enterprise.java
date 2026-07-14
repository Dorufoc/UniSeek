package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 企业资质认证实体
 */
@Data
@TableName("enterprise")
public class Enterprise {

    /** 企业记录 ID */
    @TableId
    private Long id;

    /** 用户 ID（关联 user 表） */
    private Long userId;

    /** 企业名称 */
    private String companyName;

    /** 统一社会信用代码 */
    private String creditCode;

    /** 营业执照图片 URL */
    private String licenseImgUrl;

    /** 所属行业 */
    private String industry;

    /** 企业所在地区ID */
    @TableField("region_id")
    private Long regionId;

    /** 企业描述 */
    private String description;

    /** 审核状态：0 待审核 / 1 审核通过 / 2 审核不通过 */
    private Integer auditStatus;

    /** 企业认证通过时间 */
    @TableField("audit_time")
    private LocalDateTime auditTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
