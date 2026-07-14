package com.uniseek.dto;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 职位分类 VO（树形结构返回给前端）
 */
@Data
public class CategoryVO {

    /** 分类 ID */
    private Long id;

    /** 父分类 ID */
    private Long parentId;

    /** 分类名称 */
    private String name;

    /** 排序序号 */
    private Integer sortOrder;

    /** 子分类列表 */
    private List<CategoryVO> children = new ArrayList<>();
}
