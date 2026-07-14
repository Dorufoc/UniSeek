package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.Resume;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

/**
 * 简历 Mapper
 */
@Mapper
public interface ResumeMapper extends BaseMapper<Resume> {

    /**
     * 查询简历及实名信息（LEFT JOIN real_name_auth 获取 realName）
     *
     * @param userId 用户 ID
     * @return 简历信息（含 realName 字段）
     */
    Resume selectResumeWithRealName(@Param("userId") Long userId);
}