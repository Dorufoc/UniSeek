package com.uniseek.entity;

import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 行政区划实体（省/市/区三级，GB/T 2260 标准）
 */
@Data
@TableName("region")
public class Region {

    /** 行政区划代码 */
    @TableId
    private Long id;

    /** 父级 ID（NULL 表示省级） */
    private Long parentId;

    /** 行政区划名称 */
    private String name;

    /** 层级：1 省 / 2 市 / 3 区县 */
    private Integer level;

    /** 排序权重 */
    private Integer sortOrder;

    /** 创建时间 */
    private LocalDateTime createTime;
}
