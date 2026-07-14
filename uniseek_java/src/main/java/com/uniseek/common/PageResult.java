package com.uniseek.common;

import com.baomidou.mybatisplus.core.metadata.IPage;

import java.util.List;

/**
 * 分页响应结果封装
 *
 * @param <T> 数据类型
 */
public class PageResult<T> {

    /** 数据列表 */
    private List<T> records;
    /** 总记录数 */
    private long total;
    /** 当前页码 */
    private int page;
    /** 每页大小 */
    private int pageSize;
    /** 总页数 */
    private int totalPages;

    public PageResult() {
    }

    public PageResult(List<T> records, long total, int page, int pageSize, int totalPages) {
        this.records = records;
        this.total = total;
        this.page = page;
        this.pageSize = pageSize;
        this.totalPages = totalPages;
    }

    /**
     * 从 MyBatis-Plus 分页对象创建分页结果
     */
    public static <T> PageResult<T> of(IPage<T> page) {
        int totalPages = (int) (page.getTotal() / page.getSize());
        if (page.getTotal() % page.getSize() != 0) {
            totalPages++;
        }
        return new PageResult<>(
                page.getRecords(),
                page.getTotal(),
                (int) page.getCurrent(),
                (int) page.getSize(),
                totalPages
        );
    }

    // ------ getters / setters ------

    public List<T> getRecords() {
        return records;
    }

    public void setRecords(List<T> records) {
        this.records = records;
    }

    public long getTotal() {
        return total;
    }

    public void setTotal(long total) {
        this.total = total;
    }

    public int getPage() {
        return page;
    }

    public void setPage(int page) {
        this.page = page;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }
}
