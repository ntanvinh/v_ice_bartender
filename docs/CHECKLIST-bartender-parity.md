# VIce Bartender: checklist để ngang hoặc hơn Bartender

Tạo 2026-11-12. Bạn duyệt từng dòng: đổi `[ ]` thành `[x]` cho mục đồng ý làm, gạch bỏ mục không làm, rồi mình triển khai theo thứ tự ưu tiên.

> **Lưu ý về nguồn so sánh.** Danh sách tính năng của Bartender dưới đây dựa trên hiểu biết của mình về Bartender 5/6 và trang của hãng, **chưa đối chiếu với bản 7.2**. Mục nào ghi "(kiểm tra)" cần bạn mở Bartender 7.2 xem có đúng không trước khi làm. Mình không bịa danh sách của 7.2.

Ký hiệu: **P0** làm trước (chặn trải nghiệm cơ bản), **P1** ngang Bartender, **P2** vượt Bartender. Cỡ: S (≤ nửa ngày), M (1–3 ngày), L (> 3 ngày).

## 0. Đã quyết, đã làm

- [x] Bật sẵn section Always-Hidden (`AdvancedSettings.enableAlwaysHiddenSection = true`). Xem phần "Rủi ro khi bật mặc định" bên dưới.
- [x] Bỏ "Report a Bug" khỏi sidebar.
- [ ] Chụp lại ảnh `marketing/screenshots/desktop/02-drag-and-drop-layout.png` (harness đã có lại hàng Always-Hidden, ảnh cũ chưa thay).

### Rủi ro khi bật mặc định (đã kiểm tra trong code)

- **macOS 27:** không có vấn đề. App chưa biết nằm ở đâu thì mặc định vào Visible (`SectionLayout27.swift:46`), vì layout là bảng bundle ID → section chứ không dựa vị trí vật lý.
- **macOS 14–26:** có một hành vi cần biết (đã ghi trong `FREQUENT_ISSUES.md`): macOS đặt item mới ở **ngoài cùng bên trái**, đúng chỗ của Always-Hidden, nên app mới cài có thể "biến mất" vào Always-Hidden. Trước đây tuỳ chọn tắt nên ít gặp. Đề xuất xử lý ở mục A1.
- Người đã từng đặt tuỳ chọn này thì giữ nguyên giá trị đã lưu; người chưa từng đặt sẽ thấy nó bật sau khi cập nhật.

## A. P0: nền tảng phải chắc

- [ ] **A1. Item mới luôn vào Visible, không tự ẩn (đã chốt với bạn 2026-11-12).** macOS 27: đã đúng (app chưa biết thì vào Visible, có test `SectionLayout27Tests`), người dùng tự chuyển sang Hidden/Always-Hidden. macOS 14–26: macOS đặt item mới ở ngoài cùng bên trái nên rơi vào vùng ẩn. Cần ghi nhớ các item đã thấy và đưa item lần đầu xuất hiện sang Visible bằng ⌘-drag có sẵn. **Chưa làm vì không có máy macOS 14–26 để kiểm tra**, mà thao tác này chiếm con trỏ chuột. Cỡ M.
- [ ] **A2. Chạy thật trên máy macOS 27.2 các luồng đã có test đơn vị nhưng chưa chạy end-to-end:** thả item giữa các hàng Layout, reorder hàng Visible bằng ⌘-drag, ẩn/hiện qua hover và click. Các learnings ghi rõ chưa chạy trọn luồng. Cỡ M.
- [ ] **A3. Reorder cho hàng Hidden và Always-Hidden trên macOS 27.** Hiện chỉ reorder được hàng Visible; hai hàng ẩn "không vẽ gì nên không kéo được". Cần tìm cách (hiện tạm rồi kéo, hoặc lưu thứ tự trong Ice và chỉ áp dụng khi hiện). Cỡ L, rủi ro cao.

## B. P1: tính năng Bartender có mà VIce Bartender chưa có

Các mục đầu đã nằm trong roadmap README (chưa tick).

- [ ] **B2. Trigger hiện item khi có điều kiện** (kiểm tra bản 7.2 hỗ trợ trigger nào): khi item cập nhật/đổi icon, theo mạng Wi-Fi, khi cắm sạc/pin thấp, khi mở app nào đó, theo màn hình ngoài, theo Focus, theo script. Cỡ L; làm từng loại trigger một.
- [ ] **B3. Hotkey tạm hiện một item cụ thể** (README: "Temporarily show individual menu bar items"). Cỡ M.
- [ ] **B4. Hotkey bật/tắt auto-rehide** (README, chưa tick). Cỡ S.
- [ ] **B5. Spacer (khoảng cách) tuỳ ý giữa các item** (README: "Individual spacer items"). Cỡ M. Trên macOS 27 cần xem có vẽ được spacer không vì thanh menu do `MenuBarAgent` vẽ.
- [ ] **B7. Điều khiển bằng bàn phím trong Ice Bar và Search** (mũi tên, Enter để bấm item, Esc). Kiểm tra mức hiện có rồi bổ sung. Cỡ M.
- [x] **B9. Hiện item ẩn tạm 10 giây khi trạng thái đổi (macOS 27, đã làm 2026-11-12, chưa chạy thử trên thanh menu thật).** Chỉ đọc Accessibility (bạn đã chọn): mô tả, tiêu đề, tooltip của item. Cấu hình theo app, mặc định bật, chuột phải vào tile trong Menu Bar Layout. App không công bố chữ nào thì mục bị tắt kèm giải thích; item ở Always-Hidden luôn ẩn. Sau mỗi lần hiện có 30 giây im lặng để app đổi chữ liên tục (số CPU, đồng hồ) không làm thanh menu nhấp nháy. Mã: `StatusChange27.swift` (có test), `StatusReveal27.swift`. **Còn lại:** (a) kiểm tra trên máy thật xem Accessibility của item đang bị ẩn có còn cập nhật chữ không, nếu không thì tính năng không bao giờ chạy; (b) macOS 14–26 chưa làm (item ẩn bị đẩy ra ngoài màn hình, chụp từng treo máy); (c) nếu muốn bắt cả đổi icon thì cần cách chụp, xem phương án "hiện chớp nhoáng" đã loại. Cỡ M cho phần còn lại.
- [ ] **B10. Ẩn icon của VIce Bartender** (chỉ mở qua hotkey/Spotlight). Trên macOS 27 liên quan quyền Control Center, cần thử kỹ. Cỡ S–M.
- [ ] **B11. Điều khiển từ bên ngoài**: URL scheme, AppleScript hoặc Shortcuts action (hiện/ẩn section, đổi profile). Cỡ M.
- [ ] **B12. Nhập/xuất cấu hình** (backup, chuyển máy). Cỡ S.

## C. Giao diện thanh menu (README mục "Menu bar appearance", chưa tick)

- [ ] **C1. Bỏ nền thanh menu.** Cỡ M.
- [ ] **C2. Bo góc màn hình.** Cỡ M.
- [ ] **C3. Cấu hình khác nhau cho chế độ sáng/tối.** Cỡ S–M.
- [ ] **C4. Tuỳ biến giao diện Ice Bar** (màu, bo góc, kích thước icon, vị trí). Cỡ M.

## D. P2: ý tưởng để vượt Bartender (cần bạn duyệt)

- [ ] **D1. Gợi ý ẩn thông minh:** thống kê item nào ít khi bấm và đề xuất chuyển sang Hidden/Always-Hidden, một nút để áp dụng. Cỡ M.
- [ ] **D2. Tự đổi profile theo ngữ cảnh** (đang họp, đang chia sẻ màn hình, đang chạy pin) kết hợp B1 và B2. Cỡ M sau khi có B1.
- [ ] **D3. Onboarding 3 bước** khi mở lần đầu: cấp quyền, chọn item ẩn với gợi ý sẵn, bật Ice Bar nếu có tai thỏ. Cỡ M.
- [ ] **D4. Chẩn đoán trong app:** một trang "Tình trạng" cho biết quyền nào thiếu, item nào không ẩn được và vì sao, thay cho việc người dùng tự báo lỗi. Thay chỗ của nút Report a Bug đã bỏ. Cỡ M.
- [ ] **D5. Tìm kiếm item nhanh kiểu Spotlight** với hotkey toàn cục, gõ tên để bấm item, hỗ trợ tìm theo app. Search đã có; bổ sung bấm trực tiếp và ghi nhớ item hay dùng. Cỡ S–M.
- [ ] **D6. Hỗ trợ tiếng Việt đầy đủ** (giao diện, tài liệu, ảnh chụp). Bartender không có tiếng Việt nên đây là lợi thế thị trường. Cỡ M.
- [ ] **D7. Mã nguồn mở, miễn phí, không cần tài khoản:** giữ làm điểm bán chính trong trang giới thiệu (README, marketing). Cỡ S.
- [ ] **D8. Cập nhật tự động có changelog trong app.** Sparkle đã có; thêm màn "Có gì mới" sau mỗi lần cập nhật. Cỡ S.

## E. Chất lượng và phát hành

- [ ] **E1. Chụp lại ảnh marketing** và sửa mô tả trong `marketing/screenshots/desktop/captures.json`, `marketing/screenshots/features.json` cho khớp (hàng Always-Hidden nay là mặc định). Cỡ S.
- [ ] **E2. Cập nhật README:** tick các mục đã làm, bỏ ghi chú "chưa có". Cỡ S.
- [ ] **E3. Bộ test tự động mở rộng** cho `ConcealmentPlanner27`, `SectionLayout27`, `ItemReorder27` (đã có 219 test) lên các luồng mới ở nhóm B. Cỡ M, làm song song.
- [ ] **E4. Hiệu năng:** đo CPU/RAM khi chạy nền (quét Accessibility trên macOS 27 có thể tốn pin). Mục tiêu so được với Bartender. Cỡ M.
- [ ] **E5. Ký và notarize bản phát hành**, kiểm tra Gatekeeper trên máy sạch. Cỡ S.
- [x] **E6. Khoá Sparkle riêng (đã làm 2026-11-12).** Đã tạo cặp khoá mới trong Keychain của máy này; `SUPublicEDKey` trong `Ice/Resources/Info.plist` là `FimZWmagD8zoF1BUYps/MBb9+ytibounCnTIYFouwXg=`, khớp với khoá trong Keychain (đã so sánh) và với app vừa build. **Việc bạn cần làm:** sao lưu khoá riêng (`generate_keys -x <file>`, cất ngoài repo; mất khoá thì không ký được bản cập nhật nào nữa) và phát hành bản đầu tiên; repo chưa có release nên feed đang trả 404. Bản đã cài từ trước mang khoá cũ của Jordan Baird sẽ không nhận được cập nhật tự động, cần cài tay bản mới một lần.

## Thứ tự đề xuất

1. A1, A2, A6 (đúng và ổn định trước).
2. B4, B12, B10, B7 (nhỏ, thấy ngay).
3. B1 rồi B2, B3 (nhóm tính năng giá trị nhất so với Bartender).
4. B5, B6, C1–C4.
5. D1–D6 sau cùng, theo mục bạn duyệt.
