package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 职位分类实体
 */
@Data
@TableName("category")
public class Category {

    /** 分类 ID */
    @TableId
    private Long id;

    /** 父分类 ID（顶级分类为 NULL） */
    private Long parentId;

    /** 分类名称 */
    private String name;

    /** 排序序号 */
    private Integer sortOrder;

    /** 创建时间 */
    private LocalDateTime createTime;
}
