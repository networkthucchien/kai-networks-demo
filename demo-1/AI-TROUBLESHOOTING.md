# Dùng AI hỗ trợ troubleshoot (áp dụng cho lab này)

Mục tiêu: học cách dùng AI (Claude Code hoặc chatbot khác) như **đồng nghiệp senior ngồi cạnh**, không phải **oracle trả đáp án**. Hỏi thẳng "lỗi gì, sửa sao" AI sẽ trả lời đúng ngay — nhưng bạn mất luôn phần luyện kỹ năng đọc `show run`/`show ip vrrp` và ghép triệu chứng với nguyên nhân.

## Nguyên tắc

1. **AI thu thập & đối chiếu dữ liệu nhanh hơn bạn — không nghĩ hộ bạn.** Paste output lệnh thật, không mô tả bằng lời.
2. **Không hỏi "lỗi gì" — hỏi "giả thuyết nào khớp dữ liệu này, và lệnh nào loại trừ được chúng".** AI trả lời hướng điều tra, bạn tự chạy lệnh xác minh.
3. **Không mở phần "Lời giải tham khảo" trong README rồi paste cho AI.** Mất tác dụng luyện tập — chỉ mở khi đã bí thật sự và muốn đối chiếu.
4. **Yêu cầu AI giải thích *vì sao*, không chỉ đưa lệnh fix.** Nếu AI đưa lệnh mà không giải thích cơ chế (VRRP advertisement, OSPF LSA...), hỏi lại "vì sao lệnh này sửa được triệu chứng X".

## Quy trình gợi ý (lặp vòng hypothesis → verify)

### Bước 1 — Thu thập triệu chứng
Chạy lệnh thật trên các node, copy nguyên output:
```bash
docker exec clab-chaos-vrrp-lab-r1 vtysh -c "show ip vrrp"
docker exec clab-chaos-vrrp-lab-r2 vtysh -c "show ip vrrp"
docker exec clab-chaos-vrrp-lab-host-a ping -c 4 10.0.12.2
```

**Prompt mẫu:**
> Đây là output `show ip vrrp` trên r1 và r2 trong lab VRRP+OSPF (topology: r1/r2 là gateway LAN 10.0.10.0/24 dùng VRRP VIP 10.0.10.1, phía sau là backbone qua OSPF). Cả hai đều hiện `Master`. Dựa trên output này, những giả thuyết nào giải thích được, và lệnh `show` nào tôi nên chạy tiếp để loại trừ từng giả thuyết?
> ```
> <paste output>
> ```

### Bước 2 — Khoanh vùng lớp lỗi
Đừng để AI đoán mò — cung cấp thêm `show run` khi nó yêu cầu. Hỏi AI phân biệt: đây là lỗi ở **lớp VRRP** (Master/Backup election) hay **lớp routing** (OSPF), vì hai triệu chứng trong bài (split-brain và mất route khi failover) là hai lỗi độc lập.

**Prompt mẫu:**
> Đây là `show run` của r1 và r2 (chỉ phần `interface eth1` và `router ospf`). So sánh hai cấu hình, chỉ ra khác biệt có khả năng gây split-brain VRRP. Đừng đưa lệnh sửa vội — giải thích cơ chế trước.

### Bước 3 — Verify trước khi sửa
Trước khi gõ lệnh fix, tự đối chiếu lại: VRID hai bên có khớp? VIP có trùng IP nào khác trong subnet không? Priority đúng ý đồ (r1 cao hơn) chưa?

### Bước 4 — Đề xuất fix, hiểu rồi mới gõ
**Prompt mẫu:**
> Tôi nghi ngờ r2 dùng sai VRID/VIP. Nếu đúng, lệnh vtysh nào để sửa mà không phá cấu hình OSPF hiện có? Giải thích từng dòng lệnh làm gì.

Gõ lệnh, xác minh lại bằng `show ip vrrp` — thấy r1 Master/r2 Backup thì mới qua bước tiếp.

### Bước 5 — Lặp lại cho triệu chứng thứ hai
Triệu chứng "tắt r1 thì mất mạng dù r2 sống" là lỗi khác (OSPF network sai) — lặp lại bước 1–4 với dữ liệu `show ip ospf route`, `show ip ospf database` thay vì `show ip vrrp`.

## Bảng prompt mẫu theo giai đoạn

| Giai đoạn | Việc cần AI làm | Không nên hỏi |
|---|---|---|
| Thu thập triệu chứng | Đọc output, liệt kê giả thuyết + lệnh loại trừ | "Lỗi gì vậy?" |
| Khoanh vùng lớp lỗi | So sánh config hai router, chỉ điểm khác biệt bất thường | "Sửa file nào?" |
| Đề xuất fix | Lệnh sửa + giải thích cơ chế, cảnh báo side-effect | Copy-paste lệnh không hiểu |
| Xác nhận | Gợi ý lệnh verify đầy đủ (cả trạng thái ổn định lẫn failover) | Dừng ngay sau khi ping thông 1 lần |

## Khi nào thật sự nên xem đáp án
Nếu sau ~30–45 phút tự điều tra + hỏi AI theo quy trình trên mà vẫn bí, mở `<details>` "Lời giải tham khảo" trong [`README.md`](./README.md), đối chiếu với giả thuyết bạn đã có — mục tiêu là hiểu *tại sao mình miss*, không phải chỉ copy lệnh sửa.
