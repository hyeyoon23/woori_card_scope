package dev.sample.servlet;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import java.io.IOException;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

@WebServlet("/customers/detail")
public class TestCustomerServlet extends HttpServlet {

    private CustomerService customerService;

    // ── 중분류 컬럼명 → 한글 매핑 (10개) ──
    private static final Map<String, String> SPENDING_TYPE_MAP = new LinkedHashMap<>();
    static {
        SPENDING_TYPE_MAP.put("INTERIOR_AM", "가전/가구/주방용품");
        SPENDING_TYPE_MAP.put("INSUHOS_AM", "보험/병원");
        SPENDING_TYPE_MAP.put("OFFEDU_AM", "사무통신/서적/학원");
        SPENDING_TYPE_MAP.put("TRVLEC_AM", "여행/레져/문화");
        SPENDING_TYPE_MAP.put("FSBZ_AM", "요식업");
        SPENDING_TYPE_MAP.put("SVCARC_AM", "용역/수리/건축자재");
        SPENDING_TYPE_MAP.put("DIST_AM", "유통");
        SPENDING_TYPE_MAP.put("PLSANIT_AM", "보건위생");
        SPENDING_TYPE_MAP.put("CLOTHGDS_AM", "의류/신변잡화");
        SPENDING_TYPE_MAP.put("AUTO_AM", "자동차/연료/정비");
    }

    @Override
    public void init(ServletConfig config) throws ServletException {
        super.init(config);
        ServletContext ctx = config.getServletContext();
        DataSource readDataSource = ApplicationContextListener.getReadDataSource(ctx);
        if (readDataSource == null) {
            throw new ServletException("READ_DATA_SOURCE not found in ServletContext");
        }
        customerService = new CustomerService(readDataSource);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

        String seq = req.getParameter("seq");
        if (seq == null || seq.isEmpty()) {
            resp.sendError(HttpServletResponse.SC_BAD_REQUEST, "seq parameter is required");
            return;
        }

        try {
            CustomerDTO.DetailDTO detail = customerService.getCustomerDetail(seq);
            if (detail == null) {
                resp.sendError(HttpServletResponse.SC_NOT_FOUND, "Customer not found: " + seq);
                return;
            }

            // ── JSP에 전달 ──
            req.setAttribute("customer", CustomerDTO.builder().seq(detail.seq()).build());
            req.setAttribute("totalSpending", detail.totUseAm());
            req.setAttribute("currentRank", detail.currentRankName());
            req.setAttribute("nextRank", detail.nextRankName() != null ? detail.nextRankName() : "MAX");
            req.setAttribute("remainingAmount", detail.remainingAmount());
            req.setAttribute("progressPercent", detail.progressPercent());
            req.setAttribute("totalProgressPercent", detail.totalProgressPercent());

            req.setAttribute("ageGroupLabel", detail.age());
            req.setAttribute("genderLabel", "1".equals(detail.sexCd()) ? "Male" : "Female");
            req.setAttribute("regionLabel", detail.housSidoNm());

            // 중분류 컬럼명 → 한글 변환
            String spendingTypeKr = SPENDING_TYPE_MAP.getOrDefault(detail.spendingType(), detail.spendingType());
            req.setAttribute("spendingTypes", java.util.Collections.singletonList(spendingTypeKr));

            req.getRequestDispatcher("/WEB-INF/views/customerDetail.jsp").forward(req, resp);

        } catch (SQLException e) {
            throw new ServletException("Failed to load customer detail", e);
        }
    }
}
