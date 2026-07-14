package com.uniseek.service;

import com.uniseek.dto.CategoryVO;

import java.util.List;

/**
 * 职位分类服务接口
 */
public interface CategoryService {

    /**
     * 获取全部分类树
     *
     * @return 树形分类列表
     */
    List<CategoryVO> getTree();
}
