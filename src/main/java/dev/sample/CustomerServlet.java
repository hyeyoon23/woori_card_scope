//@WebServlet("/customers")
//public class MemberListServlet extends HttpServlet {
//
//    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
//            throws ServletException, IOException {
//
//        // TODO: DAO 호출
//        List<MemberSummaryDto> list = memberDao.findMembers();
//
//        req.setAttribute("customers", list);
//
//        req.getRequestDispatcher("/WEB-INF/views/customers.jsp")
//           .forward(req, resp);
//    }
//}
//
//@WebServlet("/test-customer")
//public class TestCustomerServlet extends HttpServlet {
//
//    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
//            throws ServletException, IOException {
//
//        req.setAttribute("totalSpending", 3420);
//        req.setAttribute("currentRank", "PLATINUM");
//        req.setAttribute("nextRank", "VIP");
//        req.setAttribute("remainingAmount", 1580);
//        req.setAttribute("progressPercent", 36.8);
//
//        req.setAttribute("ageGroupLabel", "30-39");
//        req.setAttribute("genderLabel", "Female");
//        req.setAttribute("regionLabel", "Seoul");
//
//        req.setAttribute("spendingTypes",
//            java.util.Arrays.asList("Dining","Shopping","Travel","Entertainment")
//        );
//
//        CustomerDTO dummy = CustomerDTO.builder()
//                .seq("WC-2024-15748")
//                .build();
//
//        req.setAttribute("customer", dummy);
//
//        req.getRequestDispatcher("/WEB-INF/views/customerDetail.jsp")
//                .forward(req, resp);
//    }
//}