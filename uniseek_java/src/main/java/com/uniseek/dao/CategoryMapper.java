package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.Category;
import org.apache.ibatis.annotations.Mapper;

/**
 * 职位分类 Mapper
 */
@Mapper
public interface CategoryMapper extends BaseMapper<Category> {

}
