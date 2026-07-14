package com.uniseek.service.impl;

import com.uniseek.dao.CategoryMapper;
import com.uniseek.dto.CategoryVO;
import com.uniseek.entity.Category;
import com.uniseek.service.CategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * 职位分类服务实现
 */
@Service
public class CategoryServiceImpl implements CategoryService {

    @Autowired
    private CategoryMapper categoryMapper;

    @Override
    public List<CategoryVO> getTree() {
        // 1. 查询全部分类
        List<Category> allCategories = categoryMapper.selectList(null);

        // 2. 转换为 VO，并按 parentId 分组（兼容 null key）
        Map<Long, List<CategoryVO>> childrenMap = new HashMap<>();
        for (Category category : allCategories) {
            CategoryVO vo = toVO(category);
            childrenMap.computeIfAbsent(vo.getParentId(), k -> new ArrayList<>()).add(vo);
        }

        // 3. 递归组装子树
        for (CategoryVO vo : childrenMap.getOrDefault(null, new ArrayList<>())) {
            buildChildren(vo, childrenMap);
        }

        // 4. 返回顶级分类列表
        return childrenMap.getOrDefault(null, new ArrayList<>());
    }

    /**
     * 递归构建子分类
     */
    private void buildChildren(CategoryVO parent, Map<Long, List<CategoryVO>> childrenMap) {
        List<CategoryVO> children = childrenMap.getOrDefault(parent.getId(), new ArrayList<>());
        parent.setChildren(children);
        for (CategoryVO child : children) {
            buildChildren(child, childrenMap);
        }
    }

    /**
     * Entity → VO 转换
     */
    private CategoryVO toVO(Category category) {
        CategoryVO vo = new CategoryVO();
        vo.setId(category.getId());
        vo.setParentId(category.getParentId());
        vo.setName(category.getName());
        vo.setSortOrder(category.getSortOrder());
        return vo;
    }
}
