package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.uniseek.entity.Resume;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

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

    /**
     * 查询已发布到人才市场的简历（支持关键词搜索）
     *
     * @param keyword 搜索关键词
     * @return 已发布的简历列表
     */
    List<Resume> selectPublishedResumes(@Param("keyword") String keyword);
}