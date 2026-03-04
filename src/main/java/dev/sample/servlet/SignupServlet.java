package dev.sample.servlet;

import java.io.IOException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.context.annotation.AnnotationConfigApplicationContext;

import dev.sample.service.UserService;

@WebServlet("/signup")
public class SignupServlet extends HttpServlet {

	private UserService userService;

	@Override
	public void init(ServletConfig config) throws ServletException {
		AnnotationConfigApplicationContext ctx = (AnnotationConfigApplicationContext) config.getServletContext()
				.getAttribute("SPRING_CONTEXT");
		userService = ctx.getBean(UserService.class);
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		// 이미 로그인된 사용자는 고객 목록으로 리다이렉트
		HttpSession session = req.getSession(false);
		if (session != null && session.getAttribute("USER") != null) {
			resp.sendRedirect(req.getContextPath() + "/customers");
			return;
		}

		req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		req.setCharacterEncoding("UTF-8");

		String id = req.getParameter("id");
		String password = req.getParameter("password");
		String name = req.getParameter("name");

		if (id == null || password == null || name == null || id.isEmpty() || password.isEmpty() || name.isEmpty()) {
			req.setAttribute("errorMessage", "모든 항목을 입력해주세요.");
			req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
			return;
		}

		boolean success = userService.signup(id, password, name);
		if (success) {
			// 회원가입 성공 시 로그인 페이지로 이동
			resp.sendRedirect(req.getContextPath() + "/login?signup=success");
		} else {
			// 실패 시 (보통 아이디 중복)
			req.setAttribute("errorMessage", "이미 존재하는 아이디거나 가입에 실패했습니다.");
			req.getRequestDispatcher("/WEB-INF/views/signup.jsp").forward(req, resp);
		}
	}
}
