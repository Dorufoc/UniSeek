package com.uniseek.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 职位视图 VO
 */
@Data
public class TaskVO {

    /** 职位 ID */
    private Long id;

    /** 所属企业 ID */
    private Long enterpriseId;

    /** 职位分类 ID */
    private Long categoryId;

    /** 地区 ID */
    private Long regionId;

    /** 职位标题 */
    private String title;

    /** 职位描述 */
    private String description;

    /** 最低薪资 */
    private BigDecimal salaryMin;

    /** 最高薪资 */
    private BigDecimal salaryMax;

    /** 薪资单位：0 日结 / 1 时薪 / 2 月结 */
    private Integer salaryUnit;

    /** 岗位类型：1 全职 / 2 兼职 / 3 实习 */
    private Integer jobType;

    /** 招聘总名额 */
    private Integer totalQuota;

    /** 剩余名额 */
    private Integer remainingQuota;

    /** 工作地址 */
    private String address;

    /** 职位标签 */
    private List<String> tag;

    /** 经度 */
    private BigDecimal longitude;

    /** 纬度 */
    private BigDecimal latitude;

    /** 状态：0 待审 / 1 招聘中 / 2 已满员 / 3 已过期 / 4 已下架 */
    private Integer status;

    /** 报名截止时间 */
    private LocalDateTime deadline;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;

    /** 企业名称 */
    private String enterpriseName;

    /** 分类名称 */
    private String categoryName;

    /** 地区名称 */
    private String regionName;

    /** 当前用户是否已投递 */
    private Boolean hasApplied;

    /** 当前用户对该职位的投递记录 ID（已投递时有效） */
    private Long applicationId;

    /** 投递数量（热门排序用） */
    private Integer applicationCount;
}
