package dev.sample;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

import javax.servlet.ServletContext;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

@WebServlet("/customers")
public class MemberListServlet extends HttpServlet {

	private CustomerDAO memberDao;

	@Override
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		ServletContext ctx = config.getServletContext();
		DataSource readDataSource = ApplicationContextListener.getReadDataSource(ctx);
		if (readDataSource == null) {
			throw new ServletException("READ_DATA_SOURCE not found in ServletContext");
		}
		memberDao = new CustomerDAO(readDataSource);
	}

	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		try {
			List<CustomerDTO> list = memberDao.findAll();

			req.setAttribute("customers", list);
			req.getRequestDispatcher("/WEB-INF/views/customers.jsp").forward(req, resp);
		} catch (SQLException e) {
			throw new ServletException("Failed to load customers", e);
		}

	}
}
