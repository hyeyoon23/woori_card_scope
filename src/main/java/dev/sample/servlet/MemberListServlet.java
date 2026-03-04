package dev.sample.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import dev.sample.dto.CustomerDTO;
import dev.sample.service.CustomerService;

@WebServlet("/customers")
public class MemberListServlet extends HttpServlet {

	private static final int DEFAULT_PAGE_SIZE = 50;
	private CustomerService customerService;

	@Override
	public void init(ServletConfig config) throws ServletException {
		AnnotationConfigApplicationContext ctx = (AnnotationConfigApplicationContext) config.getServletContext()
				.getAttribute("SPRING_CONTEXT");

		customerService = ctx.getBean(CustomerService.class);
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		// ── 파라미터 추출 ──
		String mbrRk = req.getParameter("rank");
		String age = req.getParameter("age");
		String sexCd = req.getParameter("gender");
		String housSidoNm = req.getParameter("region");
		String seq = req.getParameter("q");

		int page = parseIntOrDefault(req.getParameter("page"), 1);
		int pageSize = parseIntOrDefault(req.getParameter("pageSize"), DEFAULT_PAGE_SIZE);

		try {
			// ── 데이터 조회 ──
			List<CustomerDTO.ListAllDTO> members;
			int totalCount;

			boolean hasFilter = isNotEmpty(mbrRk) || isNotEmpty(age) || isNotEmpty(sexCd) || isNotEmpty(housSidoNm)
					|| isNotEmpty(seq);

			if (hasFilter) {
				members = customerService.getCustomerListByFilter(mbrRk, age, sexCd, housSidoNm, seq, page, pageSize);
			} else {
				members = customerService.getCustomerList(page, pageSize);
			}
			totalCount = customerService.getTotalCount(mbrRk, age, sexCd, housSidoNm, seq);

			// ── 필터 상태 유지용 Map ──
			Map<String, String> filters = new HashMap<>();
			filters.put("rank", nvl(mbrRk));
			filters.put("age", nvl(age));
			filters.put("gender", nvl(sexCd));
			filters.put("region", nvl(housSidoNm));
			filters.put("q", nvl(seq));

			// ── JSP에 전달 ──
			req.setAttribute("members", members);
			req.setAttribute("totalCount", totalCount);
			req.setAttribute("page", page);
			req.setAttribute("pageSize", pageSize);
			req.setAttribute("filters", filters);

			req.getRequestDispatcher("/WEB-INF/views/customers.jsp").forward(req, resp);

		} catch (SQLException e) {
			throw new ServletException("Failed to load customers", e);
		}
	}

	private static int parseIntOrDefault(String s, int defaultValue) {
		if (s == null || s.isEmpty())
			return defaultValue;
		try {
			return Integer.parseInt(s);
		} catch (NumberFormatException e) {
			return defaultValue;
		}
	}

	private static boolean isNotEmpty(String s) {
		return s != null && !s.isEmpty();
	}

	private static String nvl(String s) {
		return s == null ? "" : s;
	}
}
