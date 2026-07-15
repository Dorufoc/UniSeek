package com.uniseek.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 职位搜索请求 DTO
 */
@Data
public class TaskSearchRequest {

    /** 搜索关键词（匹配标题） */
    private String keyword;

    /** 分类 ID */
    private Long categoryId;

    /** 分类 ID 集合（逗号分隔，含子孙分类） */
    private String categoryIds;

    /** 地区 ID */
    private Long regionId;

    /** 工作类型：0 全职 / 1 兼职 / 2 实习 */
    private Integer jobType;

    /** 最低薪资筛选 */
    private BigDecimal salaryMin;

    /** 最高薪资筛选 */
    private BigDecimal salaryMax;

    /** 薪资单位 */
    private Integer salaryUnit;

    /** 工作地址 */
    private String address;

    /** 标签筛选（LIKE 匹配） */
    private String tag;

    /** 排序字段：create_time / salary_max / popular */
    private String sortBy;

    /** 排序方向：asc / desc */
    private String sortOrder;

    /** 当前页码（默认 1） */
    private int page = 1;

    /** 每页条数（默认 10） */
    private int pageSize = 10;
}
