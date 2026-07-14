package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Positive;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * 职位发布/更新请求 DTO
 */
@Data
public class TaskRequest {

    /** 职位分类 ID */
    @NotNull(message = "分类不能为空")
    private Long categoryId;

    /** 地区 ID */
    @NotNull(message = "地区不能为空")
    private Long regionId;

    /** 职位标题 */
    @NotBlank(message = "职位标题不能为空")
    private String title;

    /** 职位描述 */
    private String description;

    /** 最低薪资 */
    @NotNull(message = "最低薪资不能为空")
    private BigDecimal salaryMin;

    /** 最高薪资 */
    @NotNull(message = "最高薪资不能为空")
    private BigDecimal salaryMax;

    /** 薪资单位：0 月薪 / 1 日薪 / 2 时薪 */
    @NotNull(message = "薪资单位不能为空")
    private Integer salaryUnit;

    /** 工作类型：0 全职 / 1 兼职 / 2 实习 */
    @NotNull(message = "工作类型不能为空")
    private Integer jobType;

    /** 招聘总名额 */
    @NotNull(message = "招聘名额不能为空")
    @Positive(message = "招聘名额必须大于0")
    private Integer totalQuota;

    /** 工作地址 */
    private String address;

    /** 职位标签 */
    private List<String> tag;

    /** 经度 */
    private BigDecimal longitude;

    /** 纬度 */
    private BigDecimal latitude;

    /** 报名截止时间 */
    private LocalDateTime deadline;
}
