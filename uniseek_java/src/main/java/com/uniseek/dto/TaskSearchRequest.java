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

    /** 将关键词转为 MySQL REGEXP：每个字符间插入 .*，实现不连续字符模糊匹配 */
    public String getKeywordRegex() {
        if (keyword == null || keyword.trim().isEmpty()) return null;
        String[] tokens = keyword.trim().split("\\s+");
        StringBuilder sb = new StringBuilder();
        for (String token : tokens) {
            if (sb.length() > 0) sb.append(".*");
            for (int i = 0; i < token.length(); i++) {
                if (i > 0) sb.append(".*");
                String ch = String.valueOf(token.charAt(i));
                sb.append(ch.replaceAll("([.+*?^${}()|\\[\\]\\\\])", "\\\\$1"));
            }
        }
        return sb.toString();
    }

    /** 分类 ID */
    private Long categoryId;

    /** 分类 ID 集合（逗号分隔，含子孙分类） */
    private String categoryIds;

    /** 地区 ID */
    private Long regionId;

    /** 地区 ID 集合（逗号分隔，含子孙地区） */
    private String regionIds;

    /** 工作类型：0 全职 / 1 兼职 / 2 实习 */
    private Integer jobType;

    /** 最低薪资筛选 */
    private BigDecimal salaryMin;

    /** 最高薪资筛选 */
    private BigDecimal salaryMax;

    /** 薪资单位 */
    private Integer salaryUnit;

    /** 是否包含面议（salary_min=0, salary_max=0 的职位），默认 true */
    private Boolean includeNegotiable = true;

    /** 工作地址 */
    private String address;

    /** 标签筛选，多个标签用逗号分隔（每个标签 LIKE 匹配） */
    private String tags;

    /**
     * 将 tags 按逗号分割并 trim，返回数组供 MyBatis 遍历
     */
    public String[] getTagsArray() {
        if (tags == null || tags.trim().isEmpty()) return null;
        String[] parts = tags.split(",");
        for (int i = 0; i < parts.length; i++) {
            parts[i] = parts[i].trim();
        }
        return parts;
    }

    /** 排序字段：create_time / salary_max / popular */
    private String sortBy;

    /** 排序方向：asc / desc */
    private String sortOrder;

    /** 当前页码（默认 1） */
    private int page = 1;

    /** 每页条数（默认 10） */
    private int pageSize = 10;
}
