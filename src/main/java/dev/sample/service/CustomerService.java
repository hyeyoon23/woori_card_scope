package dev.sample.service;

import java.sql.SQLException;
import java.util.List;

import javax.sql.DataSource;

import org.springframework.stereotype.Service;

import dev.sample.dao.CustomerDAO;
import dev.sample.dto.CustomerDTO;

@Service
public class CustomerService {

    private final CustomerDAO customerDAO;

    public CustomerService(CustomerDAO customerDAO) {
        this.customerDAO = customerDAO;
    }

    // ──── 전체 목록 조회 ────
    public List<CustomerDTO.ListAllDTO> getCustomerList(int page, int pageSize) throws SQLException {
        return customerDAO.findAll(page, pageSize);
    }

    // ──── 필터 목록 조회 ────
    public List<CustomerDTO.ListAllDTO> getCustomerListByFilter(String mbrRk, String age,
            String sexCd, String housSidoNm, String seq,
            int page, int pageSize) throws SQLException {
        return customerDAO.findByFilter(mbrRk, age, sexCd, housSidoNm, seq, page, pageSize);
    }

    // ──── 전체 건수 조회 (페이징 계산용) ────
    public int getTotalCount(String mbrRk, String age, String sexCd,
            String housSidoNm, String seq) throws SQLException {
        return customerDAO.getTotalCount(mbrRk, age, sexCd, housSidoNm, seq);
    }

    // ──── 상세 조회 ────
    public CustomerDTO.DetailDTO getCustomerDetail(String seq) throws SQLException {
        return customerDAO.findBySeq(seq);
    }
}