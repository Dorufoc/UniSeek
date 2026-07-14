package com.uniseek.dto;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 行政区划树形 VO
 */
@Data
public class RegionVO {

    /** 行政区划代码 */
    private Long id;

    /** 行政区划名称 */
    private String name;

    /** 层级：1 省 / 2 市 / 3 区县 */
    private Integer level;

    /** 子级区划列表 */
    private List<RegionVO> children = new ArrayList<>();
}
