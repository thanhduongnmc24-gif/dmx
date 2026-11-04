import UIKit
import PhotosUI

// MARK: - 1. Màn hình Chi tiết Ngành hàng -> Xếp hạng nhân viên, Nhập ảnh thực hiện NV, Chia Target & Xuất ảnh

final class ManHinhChiTietNganhHang: UIViewController, UITableViewDataSource, UITableViewDelegate, PHPickerViewControllerDelegate {
    private var dong: DongThiDua
    private let ngay: Date
    private let cheDo: LoaiCheDoDoanhThu
    private var danhSachXepHang: [DongXepHangNhanVienNganh] = []

    var khiCapNhatDuLieu: (() -> Void)?
    var khiYeuCauSuaDong: ((DongThiDua) -> Void)?

    private let nhanPhuDe = UILabel()
    private let nhanThongTinTarget = UILabel()
    private let bang = UITableView(frame: .zero, style: .plain)
    private let khungTongCong = UIView()
    private let nhanTongCongTrai = UILabel()
    private let nhanTongCongPhai = UILabel()
    private let khungTrong = UIView()
    private let lopPhuTai = UIView()
    private let nhanTienTrinh = UILabel()
    private let vongQuay = UIActivityIndicatorView(style: .large)

    init(dong: DongThiDua, ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        self.dong = dong
        self.ngay = ngay
        self.cheDo = cheDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func capNhatTieuDeThanhDieuHuong(_ chu: String) {
        title = chu
        let nhan = UILabel()
        nhan.text = chu
        nhan.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhan.textColor = .label
        nhan.textAlignment = .center
        nhan.numberOfLines = 0
        nhan.lineBreakMode = .byWordWrapping
        nhan.adjustsFontSizeToFitWidth = false
        navigationItem.titleView = nhan
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        capNhatTieuDeThanhDieuHuong("\(dong.tenNganhHang) (\(cheDo.tieuDe))")
        view.backgroundColor = .systemGroupedBackground

        let nutSua = UIBarButtonItem(
            image: UIImage(systemName: "pencil.circle"),
            style: .plain,
            target: self,
            action: #selector(bamSuaNganhHang)
        )
        let nutXuatAnh = UIBarButtonItem(
            image: UIImage(systemName: "photo.on.rectangle.angled"),
            style: .plain,
            target: self,
            action: #selector(bamXuatAnhBangNganhHang)
        )
        navigationItem.rightBarButtonItems = [nutXuatAnh, nutSua]

        taoGiaoDien()
        napDuLieu()
        NotificationCenter.default.addObserver(self, selector: #selector(napDuLieu), name: .duLieuDMXDaDongBo, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        napDuLieu()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func taoGiaoDien() {
        let khungDau = UIView()
        khungDau.backgroundColor = .secondarySystemGroupedBackground
        khungDau.layer.cornerRadius = 12

        nhanPhuDe.font = .systemFont(ofSize: 12, weight: .semibold)
        nhanPhuDe.textColor = .secondaryLabel
        nhanPhuDe.numberOfLines = 0
        nhanPhuDe.lineBreakMode = .byWordWrapping
        nhanPhuDe.adjustsFontSizeToFitWidth = false

        nhanThongTinTarget.font = .systemFont(ofSize: 13.5, weight: .bold)
        nhanThongTinTarget.textColor = .label
        nhanThongTinTarget.numberOfLines = 0
        nhanThongTinTarget.lineBreakMode = .byWordWrapping
        nhanThongTinTarget.adjustsFontSizeToFitWidth = false

        let nutQuetAnhNV = UIButton(type: .system)
        nutQuetAnhNV.setImage(UIImage(systemName: "camera.viewfinder"), for: .normal)
        nutQuetAnhNV.setTitle(" Nhập ảnh thực hiện NV (\(cheDo.tieuDe))", for: .normal)
        nutQuetAnhNV.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutQuetAnhNV.titleLabel?.numberOfLines = 0
        nutQuetAnhNV.titleLabel?.lineBreakMode = .byWordWrapping
        nutQuetAnhNV.titleLabel?.textAlignment = .center
        nutQuetAnhNV.titleLabel?.adjustsFontSizeToFitWidth = false
        nutQuetAnhNV.backgroundColor = .systemBlue
        nutQuetAnhNV.tintColor = .white
        nutQuetAnhNV.layer.cornerRadius = 9
        nutQuetAnhNV.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutQuetAnhNV.addTarget(self, action: #selector(bamQuetAnhNV), for: .touchUpInside)

        let nutChiaTarget = UIButton(type: .system)
        nutChiaTarget.setImage(UIImage(systemName: "person.2.badge.gearshape"), for: .normal)
        nutChiaTarget.setTitle(" Chia Target", for: .normal)
        nutChiaTarget.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        nutChiaTarget.titleLabel?.numberOfLines = 0
        nutChiaTarget.titleLabel?.lineBreakMode = .byWordWrapping
        nutChiaTarget.titleLabel?.textAlignment = .center
        nutChiaTarget.titleLabel?.adjustsFontSizeToFitWidth = false
        nutChiaTarget.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        nutChiaTarget.tintColor = .systemBlue
        nutChiaTarget.layer.cornerRadius = 9
        nutChiaTarget.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        nutChiaTarget.addTarget(self, action: #selector(bamMoChiaTarget), for: .touchUpInside)

        let hangNut = UIStackView(arrangedSubviews: [nutQuetAnhNV, nutChiaTarget])
        hangNut.axis = .horizontal
        hangNut.spacing = 8
        hangNut.distribution = .fillEqually

        let nganDau = UIStackView(arrangedSubviews: [nhanPhuDe, nhanThongTinTarget, hangNut])
        nganDau.axis = .vertical
        nganDau.spacing = 6
        nganDau.translatesAutoresizingMaskIntoConstraints = false
        khungDau.addSubview(nganDau)

        bang.dataSource = self
        bang.delegate = self
        bang.separatorStyle = .none
        bang.backgroundColor = .secondarySystemGroupedBackground
        bang.layer.cornerRadius = 12
        bang.clipsToBounds = true
        if #available(iOS 15.0, *) {
            bang.sectionHeaderTopPadding = 0
        }

        khungTongCong.backgroundColor = .secondarySystemGroupedBackground
        khungTongCong.layer.cornerRadius = 10
        nhanTongCongTrai.font = .systemFont(ofSize: 12.5, weight: .bold)
        nhanTongCongTrai.textColor = .label
        nhanTongCongTrai.numberOfLines = 0
        nhanTongCongTrai.lineBreakMode = .byWordWrapping
        nhanTongCongTrai.adjustsFontSizeToFitWidth = false

        nhanTongCongPhai.font = .systemFont(ofSize: 12.5, weight: .heavy)
        nhanTongCongPhai.textColor = .systemBlue
        nhanTongCongPhai.textAlignment = .right
        nhanTongCongPhai.numberOfLines = 0
        nhanTongCongPhai.lineBreakMode = .byWordWrapping
        nhanTongCongPhai.adjustsFontSizeToFitWidth = false
        nhanTongCongPhai.setContentCompressionResistancePriority(.required, for: .horizontal)

        [nhanTongCongTrai, nhanTongCongPhai].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungTongCong.addSubview($0)
        }

        khungTrong.backgroundColor = .secondarySystemGroupedBackground
        khungTrong.layer.cornerRadius = 12
        let nhanTrong = UILabel()
        nhanTrong.text = "Chưa chọn nhân viên nhận Target cho mặt hàng này.\nHãy bấm \"Chia Target\" để tích chọn các nhân viên phụ trách hoặc \"Nhập ảnh thực hiện NV\"."
        nhanTrong.font = .systemFont(ofSize: 13.5)
        nhanTrong.textColor = .secondaryLabel
        nhanTrong.textAlignment = .center
        nhanTrong.numberOfLines = 0
        nhanTrong.lineBreakMode = .byWordWrapping
        nhanTrong.adjustsFontSizeToFitWidth = false
        nhanTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nhanTrong)

        [khungDau, bang, khungTrong, khungTongCong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            khungDau.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            khungDau.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungDau.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            nganDau.topAnchor.constraint(equalTo: khungDau.topAnchor, constant: 10),
            nganDau.leadingAnchor.constraint(equalTo: khungDau.leadingAnchor, constant: 12),
            nganDau.trailingAnchor.constraint(equalTo: khungDau.trailingAnchor, constant: -12),
            nganDau.bottomAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: -10),

            khungTongCong.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungTongCong.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            khungTongCong.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            khungTongCong.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            nhanTongCongTrai.leadingAnchor.constraint(equalTo: khungTongCong.leadingAnchor, constant: 12),
            nhanTongCongTrai.topAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: 8),
            nhanTongCongTrai.bottomAnchor.constraint(equalTo: khungTongCong.bottomAnchor, constant: -8),
            nhanTongCongTrai.trailingAnchor.constraint(lessThanOrEqualTo: nhanTongCongPhai.leadingAnchor, constant: -8),

            nhanTongCongPhai.trailingAnchor.constraint(equalTo: khungTongCong.trailingAnchor, constant: -12),
            nhanTongCongPhai.centerYAnchor.constraint(equalTo: khungTongCong.centerYAnchor),

            bang.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 8),
            bang.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            bang.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            bang.bottomAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: -8),

            khungTrong.topAnchor.constraint(equalTo: khungDau.bottomAnchor, constant: 8),
            khungTrong.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            khungTrong.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            khungTrong.bottomAnchor.constraint(equalTo: khungTongCong.topAnchor, constant: -8),

            nhanTrong.centerXAnchor.constraint(equalTo: khungTrong.centerXAnchor),
            nhanTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nhanTrong.leadingAnchor.constraint(equalTo: khungTrong.leadingAnchor, constant: 20),
            nhanTrong.trailingAnchor.constraint(equalTo: khungTrong.trailingAnchor, constant: -20)
        ])

        taoLopPhuTienTrinh()
    }

    private func taoLopPhuTienTrinh() {
        lopPhuTai.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        lopPhuTai.isHidden = true
        lopPhuTai.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lopPhuTai)

        let hop = UIView()
        hop.backgroundColor = .systemBackground
        hop.layer.cornerRadius = 16
        hop.translatesAutoresizingMaskIntoConstraints = false
        lopPhuTai.addSubview(hop)

        vongQuay.color = .systemBlue
        vongQuay.translatesAutoresizingMaskIntoConstraints = false
        nhanTienTrinh.font = .systemFont(ofSize: 14, weight: .semibold)
        nhanTienTrinh.textAlignment = .center
        nhanTienTrinh.numberOfLines = 0
        nhanTienTrinh.lineBreakMode = .byWordWrapping
        nhanTienTrinh.adjustsFontSizeToFitWidth = false
        nhanTienTrinh.translatesAutoresizingMaskIntoConstraints = false

        hop.addSubview(vongQuay)
        hop.addSubview(nhanTienTrinh)

        NSLayoutConstraint.activate([
            lopPhuTai.topAnchor.constraint(equalTo: view.topAnchor),
            lopPhuTai.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lopPhuTai.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lopPhuTai.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hop.centerXAnchor.constraint(equalTo: lopPhuTai.centerXAnchor),
            hop.centerYAnchor.constraint(equalTo: lopPhuTai.centerYAnchor),
            hop.widthAnchor.constraint(equalToConstant: 250),
            vongQuay.topAnchor.constraint(equalTo: hop.topAnchor, constant: 18),
            vongQuay.centerXAnchor.constraint(equalTo: hop.centerXAnchor),
            nhanTienTrinh.topAnchor.constraint(equalTo: vongQuay.bottomAnchor, constant: 12),
            nhanTienTrinh.leadingAnchor.constraint(equalTo: hop.leadingAnchor, constant: 14),
            nhanTienTrinh.trailingAnchor.constraint(equalTo: hop.trailingAnchor, constant: -14),
            nhanTienTrinh.bottomAnchor.constraint(equalTo: hop.bottomAnchor, constant: -18)
        ])
    }

    @objc private func napDuLieu() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let dsTheoCheDo = dl.danhSachThiDua(theo: cheDo)
        if let capNhatDong = dsTheoCheDo.first(where: {
            $0.id == dong.id || KhoDuLieu.chuanHoaKhoaSoSanh($0.tenNganhHang) == KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        }) ?? dl.danhSachThiDua.first(where: {
            $0.id == dong.id || KhoDuLieu.chuanHoaKhoaSoSanh($0.tenNganhHang) == KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        }) {
            dong = capNhatDong
            capNhatTieuDeThanhDieuHuong("\(dong.tenNganhHang) (\(cheDo.tieuDe))")
        }

        danhSachXepHang = KhoDuLieu.dungChung.danhSachXepHangNhanVien(cho: dong, den: ngay, cheDo: cheDo)
        let soNV = danhSachXepHang.count
        let targetMoiNV = soNV > 0 ? dong.target / Double(soNV) : 0
        let donVi = dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi

        nhanPhuDe.text = "\(donVi) • \(cheDo.tieuDe) • Ngày \(TienIchNgay.hienThiNgay.string(from: ngay))"
        nhanThongTinTarget.text = "Target ST: \(dong.target.chuoiSoGonVN) (\(dong.loaiChiTieu.maBang))  •  Chia đều \(soNV) NV: \(soNV > 0 ? targetMoiNV.chuoiSoGonVN : "--")/NV"

        let tongTH = danhSachXepHang.reduce(0.0) { $0 + $1.thucHien }
        let tyLeChung = dong.target > 0 ? Int(round(tongTH / dong.target * 100.0)) : 0
        nhanTongCongTrai.text = "TỔNG (\(cheDo.tieuDe)): \(tongTH.chuoiSoGonVN) / \(dong.target.chuoiSoGonVN) • \(soNV) NV"
        nhanTongCongPhai.text = "Tỷ lệ HT: \(tyLeChung)%"

        khungTrong.isHidden = !danhSachXepHang.isEmpty
        bang.isHidden = danhSachXepHang.isEmpty
        bang.reloadData()
    }

    @objc private func bamQuetAnhNV() {
        var cauHinh = PHPickerConfiguration()
        cauHinh.filter = .images
        cauHinh.selectionLimit = 0
        if #available(iOS 15.0, *) {
            cauHinh.selection = .ordered
        }
        let picker = PHPickerViewController(configuration: cauHinh)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }

        let nhom = DispatchGroup()
        let khoaAnh = NSLock()
        var danhSach = Array<UIImage?>(repeating: nil, count: results.count)
        for (i, r) in results.enumerated() {
            guard r.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
            nhom.enter()
            r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                if let img = obj as? UIImage {
                    khoaAnh.lock()
                    danhSach[i] = img
                    khoaAnh.unlock()
                }
                nhom.leave()
            }
        }

        nhom.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            let cacAnh = danhSach.compactMap { $0 }
            guard !cacAnh.isEmpty else { return }

            self.nhanTienTrinh.text = "Đang đọc \(cacAnh.count) ảnh Thực hiện NV (\(self.cheDo.tieuDe))..."
            self.lopPhuTai.isHidden = false
            self.vongQuay.startAnimating()

            let khoaMacDinh = KhoDuLieu.chuanHoaKhoaSoSanh(self.dong.tenNganhHang)
            DichVuDocAnh.dungChung.quetAnhThiDuaNhanVien(
                danhSachAnh: cacAnh,
                tenNganhGoiY: self.dong.tenNganhHang,
                tienTrinh: { [weak self] tt in
                    self?.nhanTienTrinh.text = tt
                },
                hoanTat: { [weak self] cacKhoi in
                    guard let self = self else { return }
                    self.vongQuay.stopAnimating()
                    self.lopPhuTai.isHidden = true

                    if cacKhoi.isEmpty {
                        let tb = UIAlertController(
                            title: "Chưa đọc được dòng nhân viên",
                            message: "Hãy chụp rõ cột mã - tên nhân viên và cột số thực hiện rồi thử lại.",
                            preferredStyle: .alert
                        )
                        tb.addAction(UIAlertAction(title: "Đóng", style: .default))
                        self.present(tb, animated: true)
                        return
                    }

                    var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
                    let bangMoi = KhoDuLieu.dungChung.gopKetQuaThiDuaNhanVien(
                        hienTai: dl.thiDuaNhanVien(theo: self.cheDo),
                        mangKhoiNV: cacKhoi,
                        ngay: self.ngay,
                        cheDo: self.cheDo,
                        khoaNganhMacDinh: khoaMacDinh
                    )
                    dl.ganThiDuaNhanVien(bangMoi, theo: self.cheDo)
                    KhoDuLieu.dungChung.luu(dl)
                    self.napDuLieu()
                    self.khiCapNhatDuLieu?()
                }
            )
        }
    }

    @objc private func bamMoChiaTarget() {
        let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(dong.tenNganhHang)
        let vc = ManHinhChiaTarget(ngay: ngay, khoaNganhChonMacDinh: khoa)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func bamSuaNganhHang() {
        khiYeuCauSuaDong?(dong)
    }

    // MARK: - Bảng xếp hạng nhân viên của ngành hàng

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSachXepHang.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = danhSachXepHang[indexPath.row]
        let chuoiTen = "\(item.hoTen) - \(item.maNV)"
        let rongTen = max(100, tableView.bounds.width - 230)
        let fontTen = UIFont.systemFont(ofSize: 12, weight: .bold)
        let rect = (chuoiTen as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        return max(54, ceil(rect.height) + 22)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 44))
        header.backgroundColor = .tertiarySystemGroupedBackground

        let nhanTrai = UILabel()
        nhanTrai.text = "#  NHÂN VIÊN (Chạm sửa)"
        nhanTrai.font = .systemFont(ofSize: 11, weight: .bold)
        nhanTrai.textColor = .secondaryLabel
        nhanTrai.numberOfLines = 0
        nhanTrai.lineBreakMode = .byWordWrapping
        nhanTrai.adjustsFontSizeToFitWidth = false

        let nhanPhai = UILabel()
        nhanPhai.text = "THỰC HIỆN • CÒN/VƯỢT • % HT"
        nhanPhai.font = .systemFont(ofSize: 11, weight: .bold)
        nhanPhai.textColor = .secondaryLabel
        nhanPhai.textAlignment = .right
        nhanPhai.numberOfLines = 0
        nhanPhai.lineBreakMode = .byWordWrapping
        nhanPhai.adjustsFontSizeToFitWidth = false

        [nhanTrai, nhanPhai].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            header.addSubview($0)
        }
        NSLayoutConstraint.activate([
            nhanTrai.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 10),
            nhanTrai.topAnchor.constraint(equalTo: header.topAnchor, constant: 4),
            nhanTrai.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
            nhanPhai.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -10),
            nhanPhai.topAnchor.constraint(equalTo: header.topAnchor, constant: 4),
            nhanPhai.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
            nhanTrai.trailingAnchor.constraint(lessThanOrEqualTo: nhanPhai.leadingAnchor, constant: -6)
        ])
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        44
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "XepHangNVNganhCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let item = danhSachXepHang[indexPath.row]
        let hang = indexPath.row + 1
        let dat = item.daDat
        let kha = item.phanTramHT >= 80.0

        let nenKhung = UIView()
        nenKhung.layer.cornerRadius = 8
        nenKhung.clipsToBounds = true
        nenKhung.backgroundColor = dat
            ? UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1)
            : (kha ? UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1) : UIColor(red: 1.0, green: 0.99, blue: 0.92, alpha: 1))
        nenKhung.translatesAutoresizingMaskIntoConstraints = false
        cell.contentView.addSubview(nenKhung)

        let thanhTienDo = UIView()
        thanhTienDo.backgroundColor = dat
            ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1)
            : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.94, blue: 0.54, alpha: 0.65))
        thanhTienDo.translatesAutoresizingMaskIntoConstraints = false
        nenKhung.addSubview(thanhTienDo)

        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold)

        let nhanHang = UILabel()
        nhanHang.text = KhoDuLieu.huyChuongHang(hang)
        nhanHang.font = fontDongNhat
        nhanHang.textAlignment = .center
        nhanHang.numberOfLines = 0
        nhanHang.lineBreakMode = .byWordWrapping
        nhanHang.adjustsFontSizeToFitWidth = false

        let nhanTen = UILabel()
        nhanTen.text = "\(item.hoTen) - \(item.maNV)"
        nhanTen.font = .systemFont(ofSize: 12, weight: .bold)
        nhanTen.textColor = .label
        nhanTen.numberOfLines = 0
        nhanTen.lineBreakMode = .byWordWrapping
        nhanTen.adjustsFontSizeToFitWidth = false

        let nhanThucHien = UILabel()
        nhanThucHien.text = "\(item.thucHien.chuoiSoGonVN) / \(item.targetCaNhan.chuoiSoGonVN)"
        nhanThucHien.font = fontDongNhat
        nhanThucHien.textAlignment = .right
        nhanThucHien.numberOfLines = 0
        nhanThucHien.lineBreakMode = .byWordWrapping
        nhanThucHien.adjustsFontSizeToFitWidth = false

        let vuot = item.thucHien - item.targetCaNhan
        let nhanChenh = UILabel()
        nhanChenh.text = vuot >= -0.005 ? "+\(max(0, vuot).chuoiSoGonVN)" : "-\(abs(vuot).chuoiSoGonVN)"
        nhanChenh.font = fontDongNhat
        nhanChenh.textColor = vuot >= -0.005 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : .secondaryLabel
        nhanChenh.textAlignment = .right
        nhanChenh.numberOfLines = 0
        nhanChenh.lineBreakMode = .byWordWrapping
        nhanChenh.adjustsFontSizeToFitWidth = false

        let nhanBadge = UILabel()
        nhanBadge.text = "\(Int(round(item.phanTramHT)))%"
        nhanBadge.font = fontDongNhat
        nhanBadge.textAlignment = .center
        nhanBadge.numberOfLines = 0
        nhanBadge.lineBreakMode = .byWordWrapping
        nhanBadge.adjustsFontSizeToFitWidth = false
        nhanBadge.layer.cornerRadius = 6
        nhanBadge.clipsToBounds = true
        nhanBadge.backgroundColor = dat
            ? UIColor(red: 0.80, green: 0.96, blue: 0.85, alpha: 1)
            : (kha ? UIColor(red: 0.82, green: 0.89, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.92, blue: 0.75, alpha: 1))
        nhanBadge.textColor = dat
            ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
            : (kha ? UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1) : UIColor(red: 0.71, green: 0.33, blue: 0.04, alpha: 1))

        [nhanHang, nhanTen, nhanThucHien, nhanChenh, nhanBadge].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            nenKhung.addSubview($0)
        }

        let tyLe = CGFloat(min(1.0, max(0.03, item.phanTramHT / 100.0)))
        NSLayoutConstraint.activate([
            nenKhung.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 3),
            nenKhung.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -3),
            nenKhung.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 6),
            nenKhung.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -6),

            thanhTienDo.leadingAnchor.constraint(equalTo: nenKhung.leadingAnchor),
            thanhTienDo.topAnchor.constraint(equalTo: nenKhung.topAnchor),
            thanhTienDo.bottomAnchor.constraint(equalTo: nenKhung.bottomAnchor),
            thanhTienDo.widthAnchor.constraint(equalTo: nenKhung.widthAnchor, multiplier: tyLe),

            nhanHang.leadingAnchor.constraint(equalTo: nenKhung.leadingAnchor, constant: 6),
            nhanHang.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanHang.widthAnchor.constraint(equalToConstant: 26),

            nhanBadge.trailingAnchor.constraint(equalTo: nenKhung.trailingAnchor, constant: -6),
            nhanBadge.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanBadge.widthAnchor.constraint(equalToConstant: 48),
            nhanBadge.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),

            nhanChenh.trailingAnchor.constraint(equalTo: nhanBadge.leadingAnchor, constant: -6),
            nhanChenh.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanChenh.widthAnchor.constraint(equalToConstant: 56),

            nhanThucHien.trailingAnchor.constraint(equalTo: nhanChenh.leadingAnchor, constant: -6),
            nhanThucHien.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor),
            nhanThucHien.widthAnchor.constraint(greaterThanOrEqualToConstant: 68),

            nhanTen.leadingAnchor.constraint(equalTo: nhanHang.trailingAnchor, constant: 4),
            nhanTen.trailingAnchor.constraint(lessThanOrEqualTo: nhanThucHien.leadingAnchor, constant: -6),
            nhanTen.centerYAnchor.constraint(equalTo: nenKhung.centerYAnchor)
        ])

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < danhSachXepHang.count else { return }
        let item = danhSachXepHang[indexPath.row]
        let hop = UIAlertController(
            title: "\(item.hoTen) (\(item.maNV))",
            message: "Nhập số Thực hiện (\(cheDo.tieuDe)) cho mặt hàng \(dong.tenNganhHang):",
            preferredStyle: .alert
        )
        hop.addTextField { tf in
            tf.placeholder = "Thực hiện"
            tf.keyboardType = .decimalPad
            if item.thucHien > 0 {
                tf.text = item.thucHien.chuoiSoGonVN.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")
            }
        }
        hop.addAction(UIAlertAction(title: "Lưu", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let chu = (hop.textFields?.first?.text ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
            let giaTri = Double(chu) ?? 0
            let khoa = KhoDuLieu.chuanHoaKhoaSoSanh(self.dong.tenNganhHang)
            var dl = KhoDuLieu.dungChung.duLieu(cho: self.ngay)
            var bangNV = dl.thiDuaNhanVien(theo: self.cheDo)
            bangNV[khoa, default: [:]][item.maNV] = giaTri
            dl.ganThiDuaNhanVien(bangNV, theo: self.cheDo)
            KhoDuLieu.dungChung.luu(dl)
            self.napDuLieu()
            self.khiCapNhatDuLieu?()
        })
        hop.addAction(UIAlertAction(title: "Huỷ", style: .cancel))
        present(hop, animated: true)
    }

    // MARK: - Xuất ảnh Bảng xếp hạng nhân viên của ngành hàng

    @objc private func bamXuatAnhBangNganhHang() {
        guard !danhSachXepHang.isEmpty else { return }
        guard let anh = taoAnhBangNganhHang() else { return }
        let vc = UIActivityViewController(activityItems: [anh], applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItems?.first
        }
        present(vc, animated: true)
    }

    private func taoAnhBangNganhHang() -> UIImage? {
        let soNV = danhSachXepHang.count
        guard soNV > 0 else { return nil }
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let donVi = dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let targetMoiNV = dong.target / Double(soNV)
        let tongTH = danhSachXepHang.reduce(0.0) { $0 + $1.thucHien }
        let tyLeChung = dong.target > 0 ? Int(round(tongTH / dong.target * 100.0)) : 0

        let rong: CGFloat = 780
        let le: CGFloat = 22
        let fontTieuDe = UIFont.systemFont(ofSize: 18, weight: .heavy)
        let fontDong = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)

        let caoTenNganh = max(26, ceil((dong.tenNganhHang as NSString).boundingRect(
            with: CGSize(width: rong - le * 2 - 280, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTieuDe],
            context: nil
        ).height))
        let caoHeader: CGFloat = 30 + caoTenNganh + 12
        let caoTieuDeCot: CGFloat = 34
        let cacCaoDong: [CGFloat] = danhSachXepHang.map { item in
            let chuoiTen = "\(item.hoTen) - \(item.maNV)"
            let rect = (chuoiTen as NSString).boundingRect(
                with: CGSize(width: CGFloat(340), height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: fontTen],
                context: nil
            )
            return max(44, ceil(rect.height) + 22)
        }
        let tongCaoDong = cacCaoDong.reduce(0, +)
        let caoChan: CGFloat = 52
        let cao = le * 2 + caoHeader + caoTieuDeCot + tongCaoDong + caoChan

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: CGSize(width: rong, height: cao), format: fmt).image { ctx in
            let cg = ctx.cgContext
            UIColor.white.setFill()
            cg.fill(CGRect(x: 0, y: 0, width: rong, height: cao))

            let pLeft = NSMutableParagraphStyle(); pLeft.alignment = .left; pLeft.lineBreakMode = .byWordWrapping
            let pRight = NSMutableParagraphStyle(); pRight.alignment = .right; pRight.lineBreakMode = .byWordWrapping
            let pCenter = NSMutableParagraphStyle(); pCenter.alignment = .center; pCenter.lineBreakMode = .byWordWrapping

            ("\(donVi) • \(cheDo.tieuDe.uppercased())" as NSString).draw(at: CGPoint(x: le, y: le + 4), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12.5, weight: .bold),
                .foregroundColor: UIColor.darkGray
            ])
            (dong.tenNganhHang as NSString).draw(in: CGRect(x: le, y: le + 24, width: rong - le * 2 - 280, height: caoTenNganh + 4), withAttributes: [
                .font: fontTieuDe,
                .foregroundColor: UIColor.black,
                .paragraphStyle: pLeft
            ])
            let subRight = "Ngày \(ngayStr) • Chia đều \(soNV) NV (\(targetMoiNV.chuoiSoGonVN)/NV)"
            (subRight as NSString).draw(in: CGRect(x: rong - le - 270, y: le + 18, width: 270, height: 42), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12.5, weight: .semibold),
                .foregroundColor: UIColor.darkGray,
                .paragraphStyle: pRight
            ])

            var y = le + caoHeader
            let headerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11.5, weight: .bold),
                .foregroundColor: UIColor.gray
            ]
            ("#" as NSString).draw(at: CGPoint(x: le + 10, y: y + 8), withAttributes: headerAttr)
            ("NHÂN VIÊN" as NSString).draw(at: CGPoint(x: le + 46, y: y + 8), withAttributes: headerAttr)
            ("THỰC HIỆN" as NSString).draw(in: CGRect(x: rong - le - 300, y: y + 8, width: 110, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pRight]) { $1 })
            ("CÒN / VƯỢT" as NSString).draw(in: CGRect(x: rong - le - 180, y: y + 8, width: 96, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pRight]) { $1 })
            ("% HT" as NSString).draw(in: CGRect(x: rong - le - 68, y: y + 8, width: 62, height: 18), withAttributes: headerAttr.merging([.paragraphStyle: pCenter]) { $1 })

            y += caoTieuDeCot

            for (idx, item) in danhSachXepHang.enumerated() {
                let caoDong = cacCaoDong[idx]
                let hang = idx + 1
                let dat = item.daDat
                let kha = item.phanTramHT >= 80.0
                let bgTrack = dat ? UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1) : (kha ? UIColor(red: 0.94, green: 0.96, blue: 1.0, alpha: 1) : UIColor(red: 0.99, green: 0.99, blue: 0.91, alpha: 1))
                let bgFill = dat ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1) : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.94, blue: 0.54, alpha: 1))

                let rectRow = CGRect(x: le, y: y + 3, width: rong - le * 2, height: caoDong - 6)
                bgTrack.setFill()
                UIBezierPath(roundedRect: rectRow, cornerRadius: 8).fill()

                let pctW = CGFloat(min(1.0, max(0.03, item.phanTramHT / 100.0))) * rectRow.width
                bgFill.setFill()
                UIBezierPath(roundedRect: CGRect(x: le, y: y + 3, width: pctW, height: caoDong - 6), cornerRadius: 8).fill()

                let yGiua = y + (caoDong - 20) / 2
                (KhoDuLieu.huyChuongHang(hang) as NSString).draw(in: CGRect(x: le + 6, y: yGiua, width: 28, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: UIColor.darkGray,
                    .paragraphStyle: pCenter
                ])
                ("\(item.hoTen) - \(item.maNV)" as NSString).draw(in: CGRect(x: le + 46, y: y + 10, width: 340, height: caoDong - 20), withAttributes: [
                    .font: fontTen,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: pLeft
                ])
                ("\(item.thucHien.chuoiSoGonVN) / \(item.targetCaNhan.chuoiSoGonVN)" as NSString).draw(in: CGRect(x: rong - le - 315, y: yGiua, width: 125, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: pRight
                ])
                let vuot = item.thucHien - item.targetCaNhan
                let strDiff = vuot >= -0.005 ? "Vượt +\(max(0, vuot).chuoiSoGonVN)" : "Còn \(abs(vuot).chuoiSoGonVN)"
                (strDiff as NSString).draw(in: CGRect(x: rong - le - 184, y: yGiua, width: 100, height: 22), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: vuot >= -0.005 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor.darkGray,
                    .paragraphStyle: pRight
                ])

                let badgeRect = CGRect(x: rong - le - 68, y: y + (caoDong - 24) / 2, width: 62, height: 24)
                let badgeBg = dat ? UIColor(red: 0.86, green: 0.99, blue: 0.90, alpha: 1) : (kha ? UIColor(red: 0.86, green: 0.92, blue: 0.99, alpha: 1) : UIColor(red: 0.99, green: 0.95, blue: 0.78, alpha: 1))
                let badgeFg = dat ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : (kha ? UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1) : UIColor(red: 0.71, green: 0.33, blue: 0.04, alpha: 1))
                badgeBg.setFill()
                UIBezierPath(roundedRect: badgeRect, cornerRadius: 6).fill()
                ("\(Int(round(item.phanTramHT)))%" as NSString).draw(in: CGRect(x: badgeRect.minX, y: badgeRect.minY + 4, width: badgeRect.width, height: 18), withAttributes: [
                    .font: fontDong,
                    .foregroundColor: badgeFg,
                    .paragraphStyle: pCenter
                ])

                y += caoDong
            }

            UIColor.lightGray.setFill()
            cg.fill(CGRect(x: le, y: y + 8, width: rong - le * 2, height: 1))
            ("TỔNG CỘNG:  \(tongTH.chuoiSoGonVN) / \(dong.target.chuoiSoGonVN)   •   \(soNV) nhân viên" as NSString).draw(at: CGPoint(x: le, y: y + 20), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .heavy),
                .foregroundColor: UIColor.black
            ])
            ("Tỷ lệ HT: \(tyLeChung)%" as NSString).draw(in: CGRect(x: rong - le - 160, y: y + 20, width: 160, height: 22), withAttributes: [
                .font: UIFont.systemFont(ofSize: 13.5, weight: .heavy),
                .foregroundColor: UIColor(red: 0.11, green: 0.31, blue: 0.85, alpha: 1),
                .paragraphStyle: pRight
            ])
        }
    }
}

// MARK: - 2. BangNhanVienView (Tab Nhân viên trên màn hình chính: 2 nút nhập ảnh đã được gom lên cùng 1 hàng phía trên)

final class BangNhanVienView: UIView, UITableViewDataSource, UITableViewDelegate {
    var khiChonNhanVien: ((TongHopNhanVien) -> Void)?
    var khiBamQuetDoanhThuNV: (() -> Void)?
    var khiBamMoCaiDatNV: (() -> Void)?

    private var ngayHienTai = Date()
    private(set) var cheDoDoanhThu: LoaiCheDoDoanhThu = .luyKe
    private var kieuSapXep: KieuSapXepNhanVien = .soMonHoanThanh
    private var danhSach: [TongHopNhanVien] = []
    private var danhSachDaNapUI: [TongHopNhanVien]?
    private var cheDoDaNapUI: LoaiCheDoDoanhThu?

    private let chieuRongCot: [CGFloat] = [44, 205, 96, 84, 82, 92, 92]
    private var tongChieuRongBang: CGFloat { chieuRongCot.reduce(0, +) }

    private let nhanTieuDe = UILabel()
    private let nutSapXep = UIButton(type: .system)
    private let cuonNgang = UIScrollView()
    private let bang = UITableView(frame: .zero, style: .plain)
    private let khungTrong = UIControl()

    override init(frame: CGRect) {
        super.init(frame: frame)
        taoGiaoDien()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func taoGiaoDien() {
        backgroundColor = .clear

        nhanTieuDe.font = .systemFont(ofSize: 12.5, weight: .bold)
        nhanTieuDe.textColor = .label
        nhanTieuDe.text = "🏆 Bảng Xếp Hạng Nhân Viên"
        nhanTieuDe.numberOfLines = 0
        nhanTieuDe.lineBreakMode = .byWordWrapping
        nhanTieuDe.adjustsFontSizeToFitWidth = false

        nutSapXep.setTitle(" ⇅ \(kieuSapXep.nhanNgan)", for: .normal)
        nutSapXep.titleLabel?.font = .systemFont(ofSize: 11.5, weight: .bold)
        nutSapXep.titleLabel?.numberOfLines = 0
        nutSapXep.titleLabel?.lineBreakMode = .byWordWrapping
        nutSapXep.titleLabel?.textAlignment = .center
        nutSapXep.titleLabel?.adjustsFontSizeToFitWidth = false
        nutSapXep.backgroundColor = .secondarySystemGroupedBackground
        nutSapXep.tintColor = .systemBlue
        nutSapXep.layer.cornerRadius = 8
        nutSapXep.layer.borderWidth = 1
        nutSapXep.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.25).cgColor
        nutSapXep.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        nutSapXep.setContentHuggingPriority(.required, for: .horizontal)
        nutSapXep.setContentCompressionResistancePriority(.required, for: .horizontal)
        nutSapXep.addTarget(self, action: #selector(bamMoMenuSapXep), for: .touchUpInside)

        let thanhDieuKhien = UIStackView(arrangedSubviews: [nhanTieuDe, nutSapXep])
        thanhDieuKhien.axis = .horizontal
        thanhDieuKhien.spacing = 8
        thanhDieuKhien.alignment = .center

        cuonNgang.showsHorizontalScrollIndicator = true
        cuonNgang.showsVerticalScrollIndicator = false
        cuonNgang.bounces = false
        cuonNgang.layer.cornerRadius = 12
        cuonNgang.clipsToBounds = true
        cuonNgang.backgroundColor = .systemBackground

        bang.dataSource = self
        bang.delegate = self
        bang.rowHeight = 56
        bang.sectionHeaderHeight = 42
        bang.separatorStyle = .singleLine
        bang.separatorInset = .zero
        bang.backgroundColor = .systemBackground
        if #available(iOS 15.0, *) {
            bang.sectionHeaderTopPadding = 0
        }
        bang.translatesAutoresizingMaskIntoConstraints = false
        cuonNgang.addSubview(bang)

        khungTrong.backgroundColor = .secondarySystemGroupedBackground
        khungTrong.layer.cornerRadius = 14
        khungTrong.addTarget(self, action: #selector(bamMoCaiDat), for: .touchUpInside)

        let nhanTrong = UILabel()
        nhanTrong.text = "Chưa có nhân viên trong danh sách quản lý.\nHãy bấm vào Cài đặt (⚙️) để thêm danh sách nhân viên bạn quản lý."
        nhanTrong.font = .systemFont(ofSize: 13.5, weight: .semibold)
        nhanTrong.textColor = .secondaryLabel
        nhanTrong.textAlignment = .center
        nhanTrong.numberOfLines = 0
        nhanTrong.lineBreakMode = .byWordWrapping
        nhanTrong.adjustsFontSizeToFitWidth = false
        nhanTrong.isUserInteractionEnabled = false
        nhanTrong.translatesAutoresizingMaskIntoConstraints = false
        khungTrong.addSubview(nhanTrong)

        [thanhDieuKhien, cuonNgang, khungTrong].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            thanhDieuKhien.topAnchor.constraint(equalTo: topAnchor),
            thanhDieuKhien.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thanhDieuKhien.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            thanhDieuKhien.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            cuonNgang.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            cuonNgang.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            cuonNgang.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            cuonNgang.bottomAnchor.constraint(equalTo: bottomAnchor),

            bang.topAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.topAnchor),
            bang.bottomAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.bottomAnchor),
            bang.leadingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.leadingAnchor),
            bang.trailingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.trailingAnchor),
            bang.heightAnchor.constraint(equalTo: cuonNgang.frameLayoutGuide.heightAnchor),
            bang.widthAnchor.constraint(equalToConstant: tongChieuRongBang),

            khungTrong.topAnchor.constraint(equalTo: thanhDieuKhien.bottomAnchor, constant: 6),
            khungTrong.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            khungTrong.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            khungTrong.bottomAnchor.constraint(equalTo: bottomAnchor),

            nhanTrong.centerXAnchor.constraint(equalTo: khungTrong.centerXAnchor),
            nhanTrong.centerYAnchor.constraint(equalTo: khungTrong.centerYAnchor),
            nhanTrong.leadingAnchor.constraint(equalTo: khungTrong.leadingAnchor, constant: 20),
            nhanTrong.trailingAnchor.constraint(equalTo: khungTrong.trailingAnchor, constant: -20)
        ])
    }

    @objc private func bamMoMenuSapXep() {
        guard let vc = timViewControllerCha() else { return }
        var cacMuc: [MucChonDMX] = KieuSapXepNhanVien.allCases.map { kieu in
            MucChonDMX(tieuDe: kieu.nhan, dangChon: kieu == kieuSapXep) { [weak self] in
                guard let self = self else { return }
                self.kieuSapXep = kieu
                self.nutSapXep.setTitle(" ⇅ \(kieu.nhanNgan)", for: .normal)
                self.danhSachDaNapUI = nil
                self.capNhat(cho: self.ngayHienTai, cheDo: self.cheDoDoanhThu)
            }
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))
        vc.hienMenuChon(tieuDe: "Sắp xếp nhân viên", cacMuc: cacMuc)
    }

    @objc private func bamMoCaiDat() {
        khiBamMoCaiDatNV?()
    }

    func capNhat(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) {
        ngayHienTai = ngay
        cheDoDoanhThu = cheDo
        let moi = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: kieuSapXep, cheDo: cheDo)
        let soMonThang = KhoDuLieu.dungChung.danhSachMatHangThang(den: ngay, cheDo: cheDo).count
        nhanTieuDe.text = "🏆 Xếp Hạng \(cheDo.tieuDe) (\(moi.count) NV • \(soMonThang) môn)"

        let trong = moi.isEmpty
        khungTrong.isHidden = !trong
        cuonNgang.isHidden = trong

        if danhSachDaNapUI != moi || cheDoDaNapUI != cheDo {
            danhSach = moi
            danhSachDaNapUI = moi
            cheDoDaNapUI = cheDo
            bang.reloadData()
        }
    }

    func gan(_ moi: [TongHopNhanVien]) {
        danhSach = moi
        danhSachDaNapUI = moi
        let trong = danhSach.isEmpty
        khungTrong.isHidden = !trong
        cuonNgang.isHidden = trong
        bang.reloadData()
    }

    private func tinhChieuCaoDongNV(_ row: TongHopNhanVien) -> CGFloat {
        let rongTen = chieuRongCot[1] - 16
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let fontMa = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        let rectTen = (row.nhanVien.hoTen as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        let chuoiMa = "Mã NV: \(row.nhanVien.maNV)"
        let rectMa = (chuoiMa as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontMa],
            context: nil
        )
        return max(56, ceil(rectTen.height) + ceil(rectMa.height) + 16)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSach.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tinhChieuCaoDongNV(danhSach[indexPath.row])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: 42))
        khung.backgroundColor = .systemGray5

        let tieuDe = ["HẠNG", "NHÂN VIÊN (CHẠM XEM MÔN)", "SỐ MÔN ĐẠT", "% HT TB", "SỐ LƯỢNG", "DT QĐ", "% TỈ TRỌNG"]
        var xHienTai: CGFloat = 0
        for (i, chu) in tieuDe.enumerated() {
            let w = chieuRongCot[i]
            let nhan = UILabel(frame: CGRect(x: xHienTai + 4, y: 2, width: w - 8, height: 38))
            nhan.text = chu
            nhan.font = .systemFont(ofSize: 10.5, weight: .bold)
            nhan.textColor = .label
            nhan.numberOfLines = 0
            nhan.lineBreakMode = .byWordWrapping
            nhan.adjustsFontSizeToFitWidth = false
            nhan.textAlignment = (i == 1) ? .left : (i >= 4 ? .right : .center)
            khung.addSubview(nhan)

            xHienTai += w
            if i < tieuDe.count - 1 {
                let vach = UIView(frame: CGRect(x: xHienTai, y: 0, width: 0.5, height: 42))
                vach.backgroundColor = .separator
                khung.addSubview(vach)
            }
        }
        return khung
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "DongTongHopNV7Cot"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .default
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let row = danhSach[indexPath.row]
        let caoDong = tinhChieuCaoDongNV(row)
        let hang = indexPath.row + 1
        let laTop3 = hang <= 3

        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: caoDong))
        khung.backgroundColor = laTop3 ? UIColor.systemGreen.withAlphaComponent(0.05) : .systemBackground
        cell.contentView.addSubview(khung)

        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)
        let fontChuDongNhat = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let coDT = row.coDoanhThuCaNhan

        var x: CGFloat = 0
        for i in 0..<chieuRongCot.count {
            let w = chieuRongCot[i]
            let rect = CGRect(x: x, y: 0, width: w, height: caoDong)

            switch i {
            case 0:
                let lb = UILabel(frame: rect)
                lb.text = KhoDuLieu.huyChuongHang(hang)
                lb.font = fontDongNhat
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 1:
                let rongTen = w - 16
                let rectTen = (row.nhanVien.hoTen as NSString).boundingRect(
                    with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: [.font: fontChuDongNhat],
                    context: nil
                )
                let caoTen = max(20, ceil(rectTen.height))
                let caoMa = max(18, caoDong - caoTen - 12)

                let lbTen = UILabel(frame: CGRect(x: x + 8, y: 5, width: rongTen, height: caoTen))
                lbTen.text = row.nhanVien.hoTen
                lbTen.font = fontChuDongNhat
                lbTen.numberOfLines = 0
                lbTen.lineBreakMode = .byWordWrapping
                lbTen.adjustsFontSizeToFitWidth = false

                let lbMa = UILabel(frame: CGRect(x: x + 8, y: 5 + caoTen + 2, width: rongTen, height: caoMa))
                lbMa.text = "Mã NV: \(row.nhanVien.maNV)"
                lbMa.font = .systemFont(ofSize: 12.0, weight: .medium)
                lbMa.textColor = .secondaryLabel
                lbMa.numberOfLines = 0
                lbMa.lineBreakMode = .byWordWrapping
                lbMa.adjustsFontSizeToFitWidth = false

                khung.addSubview(lbTen)
                khung.addSubview(lbMa)
            case 2:
                let pill = UILabel(frame: rect.insetBy(dx: 5, dy: max(6, (caoDong - 34) / 2)))
                pill.text = "🏆 \(row.soMonDat)/\(row.tongMonGiao) môn"
                pill.font = fontChuDongNhat
                pill.textAlignment = .center
                pill.numberOfLines = 0
                pill.lineBreakMode = .byWordWrapping
                pill.adjustsFontSizeToFitWidth = false
                pill.layer.cornerRadius = 8
                pill.clipsToBounds = true
                pill.backgroundColor = row.soMonDat > 0 ? UIColor.systemGreen.withAlphaComponent(0.16) : UIColor.systemRed.withAlphaComponent(0.14)
                pill.textColor = row.soMonDat > 0 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor(red: 0.78, green: 0.14, blue: 0.14, alpha: 1)
                khung.addSubview(pill)
            case 3:
                let lb = UILabel(frame: rect.insetBy(dx: 4, dy: 2))
                lb.text = row.tongMonGiao > 0 ? String(format: "%.1f%%", row.phanTramHTTB) : "--"
                lb.font = fontDongNhat
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 4:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = coDT ? row.soLuongDon.chuoiSoNguyenVN : "--"
                lb.font = fontDongNhat
                lb.textColor = row.soLuongDon < 0 ? .systemRed : (row.soLuongDon > 0 ? .label : .secondaryLabel)
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 5:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = coDT ? row.doanhThuQD.chuoiSoLieu : "--"
                lb.font = fontDongNhat
                lb.textColor = row.doanhThuQD > 0
                    ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
                    : (row.doanhThuQD < 0 ? .systemRed : .secondaryLabel)
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 6:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = coDT ? String(format: "%.1f%%", row.phanTramTyTrong) : "--"
                lb.font = fontDongNhat
                lb.textColor = row.phanTramTyTrong > 0
                    ? .systemBlue
                    : (row.phanTramTyTrong < 0 ? .systemRed : .secondaryLabel)
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            default:
                break
            }

            x += w
            if i < chieuRongCot.count - 1 {
                let vach = UIView(frame: CGRect(x: x, y: 0, width: 0.5, height: caoDong))
                vach.backgroundColor = .separator
                khung.addSubview(vach)
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < danhSach.count else { return }
        khiChonNhanVien?(danhSach[indexPath.row])
    }

    // MARK: - Xuất Ảnh Bảng Xếp Hạng Tổng Hợp Nhân Viên

    func taoAnhBaoCaoNhanVien(
        ngay: Date,
        cheDo: LoaiCheDoDoanhThu? = nil,
        thongTinDonVi: String = "",
        capNhatLuc: String = ""
    ) -> UIImage? {
        let cheDoXuat = cheDo ?? cheDoDoanhThu
        let ds = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: kieuSapXep, cheDo: cheDoXuat)
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let donVi = !thongTinDonVi.isEmpty ? thongTinDonVi : (dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi)
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)
        let soMonThang = KhoDuLieu.dungChung.danhSachMatHangThang(den: ngay, cheDo: cheDoXuat).count

        let tongDTQD = ds.reduce(0.0) { $0 + $1.doanhThuQD }
        let tongDon = ds.reduce(0.0) { $0 + $1.soLuongDon }
        let tbHT = ds.isEmpty ? 0.0 : (ds.reduce(0.0) { $0 + $1.phanTramHTTB } / Double(ds.count))

        let le: CGFloat = 18
        let rongBang = tongChieuRongBang
        let rongAnh = rongBang + le * 2

        let chuPhu = "\(donVi)  •  \(cheDoXuat.tieuDe.uppercased())  •  Ngày \(ngayStr)\(capNhatLuc.isEmpty ? "" : "  •  Cập nhật: \(capNhatLuc)")"
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoPhu = max(20, ceil((chuPhu as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontPhu],
            context: nil
        ).height))

        let chuChinh = "🏆 BẢNG XẾP HẠNG NHÂN VIÊN - \(cheDoXuat.tieuDe.uppercased()) (\(ds.count) NV • \(soMonThang) MÔN)"
        let fontChinh = UIFont.systemFont(ofSize: 18.5, weight: .heavy)
        let caoChinh = max(28, ceil((chuChinh as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontChinh],
            context: nil
        ).height))

        let chuTomTat = "Tổng DT QĐ (\(cheDoXuat.tieuDe)): \(tongDTQD.chuoiSoGonVN)   •   Tổng Số lượng: \(tongDon.chuoiSoNguyenVN)   •   % HT TB: \(String(format: "%.1f%%", tbHT))"
        let fontTomTat = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoTextTomTat = max(24, ceil((chuTomTat as NSString).boundingRect(
            with: CGSize(width: rongBang - 24, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTomTat],
            context: nil
        ).height))
        let caoTomTat = caoTextTomTat + 14

        let caoHeader = caoPhu + 4 + caoChinh
        let caoTieuDeCot: CGFloat = 42
        let cacCaoDong: [CGFloat] = ds.isEmpty ? [56] : ds.map { tinhChieuCaoDongNV($0) }
        let tongCaoDong = cacCaoDong.reduce(0, +)
        let caoBang = caoTieuDeCot + tongCaoDong
        let caoAnh = le * 2 + caoHeader + 8 + caoTomTat + 10 + caoBang

        let khungBaoCao = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh))
        khungBaoCao.backgroundColor = .white
        khungBaoCao.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongBang, height: caoPhu))
        lbPhu.text = chuPhu
        lbPhu.font = fontPhu
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbPhu)

        let lbChinh = UILabel(frame: CGRect(x: le, y: le + caoPhu + 4, width: rongBang, height: caoChinh))
        lbChinh.text = chuChinh
        lbChinh.font = fontChinh
        lbChinh.textColor = .black
        lbChinh.numberOfLines = 0
        lbChinh.lineBreakMode = .byWordWrapping
        lbChinh.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbChinh)

        var y = le + caoHeader + 8

        let hopTomTat = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoTomTat))
        hopTomTat.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        hopTomTat.layer.cornerRadius = 8
        let lbTomTat = UILabel(frame: CGRect(x: 12, y: 7, width: rongBang - 24, height: caoTextTomTat))
        lbTomTat.text = chuTomTat
        lbTomTat.font = fontTomTat
        lbTomTat.textColor = .systemBlue
        lbTomTat.numberOfLines = 0
        lbTomTat.lineBreakMode = .byWordWrapping
        lbTomTat.adjustsFontSizeToFitWidth = false
        hopTomTat.addSubview(lbTomTat)
        khungBaoCao.addSubview(hopTomTat)

        y += caoTomTat + 10

        let khungBang = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoBang))
        khungBang.layer.borderWidth = 1
        khungBang.layer.borderColor = UIColor.systemGray4.cgColor
        khungBang.layer.cornerRadius = 8
        khungBang.clipsToBounds = true
        khungBaoCao.addSubview(khungBang)

        if let header = self.tableView(bang, viewForHeaderInSection: 0) {
            header.frame = CGRect(x: 0, y: 0, width: rongBang, height: caoTieuDeCot)
            khungBang.addSubview(header)
        }

        if ds.isEmpty {
            let lbTrong = UILabel(frame: CGRect(x: 0, y: caoTieuDeCot, width: rongBang, height: 56))
            lbTrong.text = "Chưa có dữ liệu nhân viên."
            lbTrong.font = .systemFont(ofSize: 12.5, weight: .medium)
            lbTrong.textColor = .gray
            lbTrong.textAlignment = .center
            lbTrong.numberOfLines = 0
            lbTrong.lineBreakMode = .byWordWrapping
            khungBang.addSubview(lbTrong)
        } else {
            let cu = self.danhSach
            self.danhSach = ds
            var yDong = caoTieuDeCot
            for i in 0..<ds.count {
                let caoDong = cacCaoDong[i]
                let cell = self.tableView(bang, cellForRowAt: IndexPath(row: i, section: 0))
                let vDong = cell.contentView
                vDong.frame = CGRect(x: 0, y: yDong, width: rongBang, height: caoDong)
                let vach = UIView(frame: CGRect(x: 0, y: caoDong - 0.5, width: rongBang, height: 0.5))
                vach.backgroundColor = .systemGray4
                vDong.addSubview(vach)
                khungBang.addSubview(vDong)
                yDong += caoDong
            }
            self.danhSach = cu
        }

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        let anh = UIGraphicsImageRenderer(size: khungBaoCao.bounds.size, format: fmt).image { ctx in
            khungBaoCao.layer.render(in: ctx.cgContext)
        }
        bang.reloadData()
        return anh
    }
}

// MARK: - 3. Màn hình Chi tiết Sức khoẻ Cá nhân Nhân viên (chia theo Lũy kế & Realtime)

final class ManHinhChiTietNhanVien: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tongHop: TongHopNhanVien
    private let ngay: Date
    private let cheDo: LoaiCheDoDoanhThu
    private var boLoc: BoLocThiDua = .tatCa
    private var danhSachMonLoc: [MonThiDuaNhanVien] = []

    private let chonBoLoc = UISegmentedControl(items: ["Tất cả", "Đạt", "Chưa đạt"])
    private let cuonNgang = UIScrollView()
    private let bang = UITableView(frame: .zero, style: .plain)
    private let chieuRongCot: [CGFloat] = [38, 210, 84, 84, 82, 86, 84, 92]
    private var tongChieuRongBang: CGFloat { chieuRongCot.reduce(0, +) }

    init(_ tongHop: TongHopNhanVien, ngay: Date = Date(), cheDo: LoaiCheDoDoanhThu = .luyKe) {
        self.tongHop = tongHop
        self.ngay = ngay
        self.cheDo = cheDo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sức khoẻ \(tongHop.nhanVien.hoTen) (\(cheDo.tieuDe))"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(bamChiaSeAnhSucKhoe)
        )
        taoGiaoDien()
        locDanhSachMon()
    }

    private func taoGiaoDien() {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let dt = dl.doanhThu
        let lich = TienIchNgay.lich
        let soNgayQua = dt.soNgayDaQua > 0 ? dt.soNgayDaQua : max(1, lich.component(.day, from: ngay))
        let tongNgayThang = dt.tongSoNgay > 0 ? dt.tongSoNgay : (lich.range(of: .day, in: .month, for: ngay)?.count ?? 30)
        let ptTienDo = dt.phanTramTienDoThang > 0 ? dt.phanTramTienDoThang : (Double(soNgayQua) / Double(max(1, tongNgayThang)) * 100.0)

        let khungTienDo = UIView()
        khungTienDo.backgroundColor = .systemBackground
        khungTienDo.layer.cornerRadius = 10
        khungTienDo.layer.borderWidth = 1
        khungTienDo.layer.borderColor = UIColor.systemGray5.cgColor

        let lbTDTrai = UILabel()
        lbTDTrai.text = "Chế độ: \(cheDo.tieuDe)  •  Tiến độ tháng: Ngày \(soNgayQua) / \(tongNgayThang)"
        lbTDTrai.font = .systemFont(ofSize: 11.5, weight: .bold)
        lbTDTrai.numberOfLines = 0
        lbTDTrai.lineBreakMode = .byWordWrapping
        lbTDTrai.adjustsFontSizeToFitWidth = false

        let lbTDPhai = UILabel()
        lbTDPhai.text = String(format: "%.1f%%", ptTienDo)
        lbTDPhai.font = .systemFont(ofSize: 11.5, weight: .bold)
        lbTDPhai.textAlignment = .right
        lbTDPhai.numberOfLines = 0
        lbTDPhai.lineBreakMode = .byWordWrapping
        lbTDPhai.adjustsFontSizeToFitWidth = false
        lbTDPhai.setContentCompressionResistancePriority(.required, for: .horizontal)

        let track = UIView()
        track.backgroundColor = .systemGray5
        track.layer.cornerRadius = 3
        track.clipsToBounds = true
        let fill = UIView()
        fill.backgroundColor = .systemBlue
        fill.layer.cornerRadius = 3
        fill.translatesAutoresizingMaskIntoConstraints = false
        track.addSubview(fill)

        [lbTDTrai, lbTDPhai, track].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            khungTienDo.addSubview($0)
        }

        let tyLeTD = CGFloat(min(1.0, max(0.02, ptTienDo / 100.0)))
        NSLayoutConstraint.activate([
            lbTDTrai.topAnchor.constraint(equalTo: khungTienDo.topAnchor, constant: 6),
            lbTDTrai.leadingAnchor.constraint(equalTo: khungTienDo.leadingAnchor, constant: 10),
            lbTDTrai.trailingAnchor.constraint(lessThanOrEqualTo: lbTDPhai.leadingAnchor, constant: -6),
            lbTDPhai.centerYAnchor.constraint(equalTo: lbTDTrai.centerYAnchor),
            lbTDPhai.trailingAnchor.constraint(equalTo: khungTienDo.trailingAnchor, constant: -10),
            track.topAnchor.constraint(equalTo: lbTDTrai.bottomAnchor, constant: 5),
            track.leadingAnchor.constraint(equalTo: khungTienDo.leadingAnchor, constant: 10),
            track.trailingAnchor.constraint(equalTo: khungTienDo.trailingAnchor, constant: -10),
            track.bottomAnchor.constraint(equalTo: khungTienDo.bottomAnchor, constant: -6),
            track.heightAnchor.constraint(equalToConstant: 5),
            fill.leadingAnchor.constraint(equalTo: track.leadingAnchor),
            fill.topAnchor.constraint(equalTo: track.topAnchor),
            fill.bottomAnchor.constraint(equalTo: track.bottomAnchor),
            fill.widthAnchor.constraint(equalTo: track.widthAnchor, multiplier: tyLeTD)
        ])

        let coDT = tongHop.coDoanhThuCaNhan
        let dtQD = tongHop.doanhThuQD
        let soDon = tongHop.soLuongDon
        let tyTrong = tongHop.phanTramTyTrong
        let tongMon = tongHop.tongMonGiao
        let soMonDat = tongHop.soMonDat
        let soMonChua = tongMon - soMonDat
        let tyLeMon = tongMon > 0 ? Int(round(Double(soMonDat) / Double(tongMon) * 100.0)) : 0

        let the1 = TheDoanhThuView(
            tieuDe: "💵 DOANH THU QĐ",
            mauBatDau: UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1),
            mauKetThuc: UIColor(red: 0.23, green: 0.25, blue: 0.89, alpha: 1)
        )
        the1.capNhatNoiDung(
            chinh: coDT ? "\(dtQD.chuoiSoGonVN)tr" : "--",
            phu: coDT ? "TỈ TRỌNG: \(String(format: "%.1f%%", tyTrong))" : "SL: --"
        )

        let the2 = TheDoanhThuView(
            tieuDe: "🏆 MÔN THI ĐUA HT",
            mauBatDau: UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1),
            mauKetThuc: UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1)
        )
        the2.capNhatNoiDung(
            chinh: "\(soMonDat)/\(tongMon)",
            phu: "HOÀN THÀNH: \(tyLeMon)% SỐ MÔN"
        )

        let the3 = TheDoanhThuView(
            tieuDe: "📦 SỐ LƯỢNG & TỈ TRỌNG",
            mauBatDau: UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1),
            mauKetThuc: UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
        )
        the3.capNhatNoiDung(
            chinh: coDT ? soDon.chuoiSoNguyenVN : "--",
            phu: coDT ? "% TỈ TRỌNG: \(String(format: "%.1f%%", tyTrong))" : "% TỈ TRỌNG: --"
        )

        let the4 = TheDoanhThuView(
            tieuDe: "📈 % HT THI ĐUA TB",
            mauBatDau: UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1),
            mauKetThuc: UIColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1)
        )
        the4.capNhatNoiDung(
            chinh: tongHop.phanTramHTTB.chuoiPhanTramVN,
            phu: "ĐẠT \(soMonDat) • CHƯA \(soMonChua)"
        )

        let hangThe = UIStackView(arrangedSubviews: [the1, the2, the3, the4])
        hangThe.axis = .horizontal
        hangThe.spacing = 6
        hangThe.distribution = .fillEqually

        chonBoLoc.selectedSegmentIndex = 0
        chonBoLoc.setTitle("Tất cả (\(tongMon))", forSegmentAt: 0)
        chonBoLoc.setTitle("Đạt (\(soMonDat))", forSegmentAt: 1)
        chonBoLoc.setTitle("Chưa đạt (\(soMonChua))", forSegmentAt: 2)
        chonBoLoc.addTarget(self, action: #selector(doiBoLoc), for: .valueChanged)
        chonBoLoc.damBaoHienThiDayDuText()

        cuonNgang.showsHorizontalScrollIndicator = true
        cuonNgang.bounces = false
        cuonNgang.layer.cornerRadius = 12
        cuonNgang.clipsToBounds = true
        cuonNgang.backgroundColor = .systemBackground

        bang.dataSource = self
        bang.delegate = self
        bang.rowHeight = 52
        bang.sectionHeaderHeight = 40
        bang.separatorStyle = .singleLine
        bang.separatorInset = .zero
        if #available(iOS 15.0, *) {
            bang.sectionHeaderTopPadding = 0
        }
        bang.translatesAutoresizingMaskIntoConstraints = false
        cuonNgang.addSubview(bang)

        [khungTienDo, hangThe, chonBoLoc, cuonNgang].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            khungTienDo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            khungTienDo.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            khungTienDo.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            khungTienDo.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            hangThe.topAnchor.constraint(equalTo: khungTienDo.bottomAnchor, constant: 8),
            hangThe.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            hangThe.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            hangThe.heightAnchor.constraint(equalToConstant: 76),

            chonBoLoc.topAnchor.constraint(equalTo: hangThe.bottomAnchor, constant: 8),
            chonBoLoc.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            chonBoLoc.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            chonBoLoc.heightAnchor.constraint(equalToConstant: 32),

            cuonNgang.topAnchor.constraint(equalTo: chonBoLoc.bottomAnchor, constant: 8),
            cuonNgang.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            cuonNgang.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            cuonNgang.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            bang.topAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.topAnchor),
            bang.bottomAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.bottomAnchor),
            bang.leadingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.leadingAnchor),
            bang.trailingAnchor.constraint(equalTo: cuonNgang.contentLayoutGuide.trailingAnchor),
            bang.heightAnchor.constraint(equalTo: cuonNgang.frameLayoutGuide.heightAnchor),
            bang.widthAnchor.constraint(equalToConstant: tongChieuRongBang)
        ])
    }

    @objc private func doiBoLoc() {
        boLoc = BoLocThiDua(rawValue: chonBoLoc.selectedSegmentIndex) ?? .tatCa
        locDanhSachMon()
    }

    private func locDanhSachMon() {
        switch boLoc {
        case .tatCa:
            danhSachMonLoc = tongHop.cacMonGiao
        case .daDat:
            danhSachMonLoc = tongHop.cacMonGiao.filter(\.daDat)
        case .chuaDat:
            danhSachMonLoc = tongHop.cacMonGiao.filter { !$0.daDat }
        }
        bang.reloadData()
    }

    private func tinhChieuCaoDongMon(_ m: MonThiDuaNhanVien) -> CGFloat {
        let chuoiTen = "\(m.tenNganhHang) (\(m.loaiChiTieu.maThe))"
        let rongTen = chieuRongCot[1] - 12
        let fontTen = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let rectTen = (chuoiTen as NSString).boundingRect(
            with: CGSize(width: rongTen, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontTen],
            context: nil
        )
        return max(50, ceil(rectTen.height) + 18)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        danhSachMonLoc.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        tinhChieuCaoDongMon(danhSachMonLoc[indexPath.row])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: 40))
        khung.backgroundColor = .systemGray5
        let tieuDe = ["#", "MÔN THI ĐUA", "THỰC HIỆN", "TARGET", "% HT", "% HT ST", "CÒN LẠI", "TIẾN ĐỘ"]
        var x: CGFloat = 0
        for (i, chu) in tieuDe.enumerated() {
            let w = chieuRongCot[i]
            let lb = UILabel(frame: CGRect(x: x + 4, y: 2, width: w - 8, height: 36))
            lb.text = chu
            lb.font = .systemFont(ofSize: 10.5, weight: .bold)
            lb.numberOfLines = 0
            lb.lineBreakMode = .byWordWrapping
            lb.adjustsFontSizeToFitWidth = false
            lb.textAlignment = (i == 1) ? .left : (i == 2 || i == 3 || i == 6 ? .right : .center)
            khung.addSubview(lb)
            x += w
        }
        return khung
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ma = "ChiTietMonNVCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: ma) ?? UITableViewCell(style: .default, reuseIdentifier: ma)
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let m = danhSachMonLoc[indexPath.row]
        let caoDong = tinhChieuCaoDongMon(m)
        let khung = UIView(frame: CGRect(x: 0, y: 0, width: tongChieuRongBang, height: caoDong))
        khung.backgroundColor = m.daDat ? UIColor.systemGreen.withAlphaComponent(0.05) : UIColor.systemRed.withAlphaComponent(0.04)
        cell.contentView.addSubview(khung)

        let fontDongNhat = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .bold)

        var x: CGFloat = 0
        for i in 0..<chieuRongCot.count {
            let w = chieuRongCot[i]
            let rect = CGRect(x: x, y: 0, width: w, height: caoDong)
            switch i {
            case 0:
                let lb = UILabel(frame: rect)
                lb.text = "\(indexPath.row + 1)"
                lb.font = fontDongNhat
                lb.textColor = .secondaryLabel
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 1:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 4))
                lb.text = "\(m.tenNganhHang) (\(m.loaiChiTieu.maThe))"
                lb.font = .systemFont(ofSize: 12.5, weight: .bold)
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 2:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = m.thucHien.chuoiSoVN
                lb.font = fontDongNhat
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 3:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = m.targetCaNhan.chuoiSoVN
                lb.font = fontDongNhat
                lb.textColor = .secondaryLabel
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 4:
                let pill = UILabel(frame: rect.insetBy(dx: 5, dy: max(4, (caoDong - 28) / 2)))
                pill.text = m.phanTramHT.chuoiPhanTramVN
                pill.font = fontDongNhat
                pill.textAlignment = .center
                pill.numberOfLines = 0
                pill.lineBreakMode = .byWordWrapping
                pill.adjustsFontSizeToFitWidth = false
                pill.layer.cornerRadius = 7
                pill.clipsToBounds = true
                pill.backgroundColor = m.daDat ? UIColor.systemGreen.withAlphaComponent(0.18) : UIColor.systemRed.withAlphaComponent(0.16)
                pill.textColor = m.daDat ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor(red: 0.78, green: 0.14, blue: 0.14, alpha: 1)
                khung.addSubview(pill)
            case 5:
                let lb = UILabel(frame: rect.insetBy(dx: 4, dy: 2))
                lb.text = m.phanTramSieuThi.chuoiPhanTramVN
                lb.font = fontDongNhat
                lb.textColor = .secondaryLabel
                lb.textAlignment = .center
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 6:
                let lb = UILabel(frame: rect.insetBy(dx: 6, dy: 2))
                lb.text = m.conLai.chuoiSoVN
                lb.font = fontDongNhat
                lb.textColor = m.conLai <= 0 ? UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1) : UIColor(red: 0.78, green: 0.14, blue: 0.14, alpha: 1)
                lb.textAlignment = .right
                lb.numberOfLines = 0
                lb.lineBreakMode = .byWordWrapping
                lb.adjustsFontSizeToFitWidth = false
                khung.addSubview(lb)
            case 7:
                let track = UIView(frame: CGRect(x: x + 8, y: (caoDong - 6) / 2, width: w - 16, height: 6))
                track.backgroundColor = .systemGray5
                track.layer.cornerRadius = 3
                track.clipsToBounds = true
                let pct = CGFloat(min(1.0, max(0.04, m.phanTramHT / 100.0)))
                let fill = UIView(frame: CGRect(x: 0, y: 0, width: (w - 16) * pct, height: 6))
                fill.backgroundColor = m.daDat ? .systemGreen : (m.phanTramHT >= 70 ? .systemOrange : .systemRed)
                track.addSubview(fill)
                khung.addSubview(track)
            default:
                break
            }
            x += w
        }
        return cell
    }

    // MARK: - Xuất / Chia sẻ ảnh Sức khoẻ chi tiết

    @objc private func bamChiaSeAnhSucKhoe() {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDo)

        var cacMuc: [MucChonDMX] = [
            MucChonDMX(tieuDe: "👤 Xuất 1 nhân viên này (\(tongHop.nhanVien.hoTen))") { [weak self] in
                guard let self = self, let anh = self.taoAnhSucKhoeNhanVien() else { return }
                self.hienChiaSe([anh])
            }
        ]

        if !dsNV.isEmpty {
            cacMuc.append(MucChonDMX(tieuDe: "📚 Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Bộ \(dsNV.count) ảnh rời)") { [weak self] in
                guard let self = self else { return }
                let cacAnh = Self.taoTatCaAnhSucKhoe(cho: self.ngay, cheDo: self.cheDo)
                guard !cacAnh.isEmpty else { return }
                self.hienChiaSe(cacAnh)
            })
            cacMuc.append(MucChonDMX(tieuDe: "🖼️ Xuất TẤT CẢ \(dsNV.count) NV đang quản lý (Gộp 1 ảnh tổng hợp)") { [weak self] in
                guard let self = self, let anhGop = Self.taoAnhGopTatCaSucKhoe(cho: self.ngay, cheDo: self.cheDo) else { return }
                self.hienChiaSe([anhGop])
            })
        }
        cacMuc.append(MucChonDMX(tieuDe: "Đóng", kieu: .huy))

        hienMenuChon(
            tieuDe: "Xuất ảnh Sức khoẻ Nhân viên (\(cheDo.tieuDe))",
            thongDiep: "Chọn xuất riêng nhân viên đang xem hoặc xuất tất cả \(dsNV.count) nhân viên đang quản lý:",
            cacMuc: cacMuc
        )
    }

    private func hienChiaSe(_ muc: [Any]) {
        let vc = UIActivityViewController(activityItems: muc, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(vc, animated: true)
    }

    static func taoAnhSucKhoe(cho tongHop: TongHopNhanVien, ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> UIImage? {
        let vc = ManHinhChiTietNhanVien(tongHop, ngay: ngay, cheDo: cheDo)
        vc.loadViewIfNeeded()
        return vc.taoAnhSucKhoeNhanVien()
    }

    static func taoTatCaAnhSucKhoe(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> [UIImage] {
        let dsNV = KhoDuLieu.dungChung.tongHopNhanVien(den: ngay, sapXep: .soMonHoanThanh, cheDo: cheDo)
        return dsNV.compactMap { taoAnhSucKhoe(cho: $0, ngay: ngay, cheDo: cheDo) }
    }

    static func taoAnhGopTatCaSucKhoe(cho ngay: Date, cheDo: LoaiCheDoDoanhThu = .luyKe) -> UIImage? {
        let cacAnh = taoTatCaAnhSucKhoe(cho: ngay, cheDo: cheDo)
        guard !cacAnh.isEmpty else { return nil }
        if cacAnh.count == 1 { return cacAnh[0] }

        let khoangCach: CGFloat = 18
        let rong = cacAnh.map { $0.size.width }.max() ?? 760
        let tongCao = cacAnh.reduce(CGFloat(0)) { $0 + $1.size.height } + CGFloat(cacAnh.count - 1) * khoangCach

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        return UIGraphicsImageRenderer(size: CGSize(width: rong, height: tongCao), format: fmt).image { ctx in
            UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: rong, height: tongCao))
            var y: CGFloat = 0
            for anh in cacAnh {
                anh.draw(in: CGRect(x: (rong - anh.size.width) / 2, y: y, width: anh.size.width, height: anh.size.height))
                y += anh.size.height + khoangCach
            }
        }
    }

    func taoAnhSucKhoeNhanVien() -> UIImage? {
        let dl = KhoDuLieu.dungChung.duLieu(cho: ngay)
        let dt = dl.doanhThu
        let lich = TienIchNgay.lich
        let soNgayQua = dt.soNgayDaQua > 0 ? dt.soNgayDaQua : max(1, lich.component(.day, from: ngay))
        let tongNgayThang = dt.tongSoNgay > 0 ? dt.tongSoNgay : (lich.range(of: .day, in: .month, for: ngay)?.count ?? 30)
        let ptTienDo = dt.phanTramTienDoThang > 0 ? dt.phanTramTienDoThang : (Double(soNgayQua) / Double(max(1, tongNgayThang)) * 100.0)
        let donVi = dl.thongTinDonVi.isEmpty ? "ĐIỆN MÁY XANH" : dl.thongTinDonVi
        let ngayStr = TienIchNgay.hienThiNgay.string(from: ngay)

        let dsMon = danhSachMonLoc
        let le: CGFloat = 18
        let rongBang = tongChieuRongBang
        let rongAnh = rongBang + le * 2

        let chuPhu = "\(donVi)  •  \(cheDo.tieuDe.uppercased())  •  Mã NV: \(tongHop.nhanVien.maNV)  •  Ngày \(ngayStr)"
        let fontPhu = UIFont.systemFont(ofSize: 12.5, weight: .bold)
        let caoPhu = max(20, ceil((chuPhu as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontPhu],
            context: nil
        ).height))

        let chuChinh = "SỨC KHOẺ CHI TIẾT (\(cheDo.tieuDe.uppercased())): \(tongHop.nhanVien.hoTen.uppercased())"
        let fontChinh = UIFont.systemFont(ofSize: 19, weight: .heavy)
        let caoChinh = max(28, ceil((chuChinh as NSString).boundingRect(
            with: CGSize(width: rongBang, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: fontChinh],
            context: nil
        ).height))

        let caoHeader = caoPhu + 4 + caoChinh
        let caoTienDo: CGFloat = 38
        let caoKPI: CGFloat = 86
        let caoTieuDeBang: CGFloat = 40
        let cacCaoDong: [CGFloat] = dsMon.isEmpty ? [50] : dsMon.map { tinhChieuCaoDongMon($0) }
        let tongCaoDong = cacCaoDong.reduce(0, +)
        let caoBang = caoTieuDeBang + tongCaoDong
        let caoAnh = le * 2 + caoHeader + 10 + caoTienDo + 10 + caoKPI + 12 + caoBang

        let khungBaoCao = UIView(frame: CGRect(x: 0, y: 0, width: rongAnh, height: caoAnh))
        khungBaoCao.backgroundColor = .white
        khungBaoCao.overrideUserInterfaceStyle = .light

        let lbPhu = UILabel(frame: CGRect(x: le, y: le, width: rongBang, height: caoPhu))
        lbPhu.text = chuPhu
        lbPhu.font = fontPhu
        lbPhu.textColor = .darkGray
        lbPhu.numberOfLines = 0
        lbPhu.lineBreakMode = .byWordWrapping
        lbPhu.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbPhu)

        let lbChinh = UILabel(frame: CGRect(x: le, y: le + caoPhu + 4, width: rongBang, height: caoChinh))
        lbChinh.text = chuChinh
        lbChinh.font = fontChinh
        lbChinh.textColor = .black
        lbChinh.numberOfLines = 0
        lbChinh.lineBreakMode = .byWordWrapping
        lbChinh.adjustsFontSizeToFitWidth = false
        khungBaoCao.addSubview(lbChinh)

        var y = le + caoHeader + 10

        let hopTD = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoTienDo))
        hopTD.backgroundColor = .white
        hopTD.layer.cornerRadius = 10
        hopTD.layer.borderWidth = 1
        hopTD.layer.borderColor = UIColor.systemGray4.cgColor

        let lbTDTrai = UILabel(frame: CGRect(x: 12, y: 6, width: 360, height: 16))
        lbTDTrai.text = "Tiến độ tháng   Ngày \(soNgayQua) / \(tongNgayThang)"
        lbTDTrai.font = .systemFont(ofSize: 12, weight: .bold)
        lbTDTrai.textColor = .black
        lbTDTrai.numberOfLines = 0
        lbTDTrai.lineBreakMode = .byWordWrapping
        let lbTDPhai = UILabel(frame: CGRect(x: rongBang - 112, y: 6, width: 100, height: 16))
        lbTDPhai.text = String(format: "%.1f%%", ptTienDo)
        lbTDPhai.font = .systemFont(ofSize: 12, weight: .bold)
        lbTDPhai.textColor = .black
        lbTDPhai.textAlignment = .right

        let trackTD = UIView(frame: CGRect(x: 12, y: 26, width: rongBang - 24, height: 6))
        trackTD.backgroundColor = .systemGray5
        trackTD.layer.cornerRadius = 3
        trackTD.clipsToBounds = true
        let tyLeTD = CGFloat(min(1.0, max(0.02, ptTienDo / 100.0)))
        let fillTD = UIView(frame: CGRect(x: 0, y: 0, width: (rongBang - 24) * tyLeTD, height: 6))
        fillTD.backgroundColor = .systemBlue
        trackTD.addSubview(fillTD)

        hopTD.addSubview(lbTDTrai)
        hopTD.addSubview(lbTDPhai)
        hopTD.addSubview(trackTD)
        khungBaoCao.addSubview(hopTD)

        y += caoTienDo + 10

        let coDT = tongHop.coDoanhThuCaNhan
        let dtQD = tongHop.doanhThuQD
        let soDon = tongHop.soLuongDon
        let tyTrong = tongHop.phanTramTyTrong
        let tongMon = tongHop.tongMonGiao
        let soMonDat = tongHop.soMonDat
        let soMonChua = tongMon - soMonDat
        let tyLeMon = tongMon > 0 ? Int(round(Double(soMonDat) / Double(tongMon) * 100.0)) : 0

        let the1 = TheDoanhThuView(
            tieuDe: "💵 DOANH THU QĐ",
            mauBatDau: UIColor(red: 0.14, green: 0.39, blue: 0.92, alpha: 1),
            mauKetThuc: UIColor(red: 0.23, green: 0.25, blue: 0.89, alpha: 1)
        )
        the1.capNhatNoiDung(
            chinh: coDT ? "\(dtQD.chuoiSoGonVN)tr" : "--",
            phu: coDT ? "TỈ TRỌNG: \(String(format: "%.1f%%", tyTrong))" : "SL: --",
            coLon: true
        )

        let the2 = TheDoanhThuView(
            tieuDe: "🏆 MÔN THI ĐUA HT",
            mauBatDau: UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1),
            mauKetThuc: UIColor(red: 0.85, green: 0.47, blue: 0.02, alpha: 1)
        )
        the2.capNhatNoiDung(
            chinh: "\(soMonDat)/\(tongMon)",
            phu: "HOÀN THÀNH: \(tyLeMon)% SỐ MÔN",
            coLon: true
        )

        let the3 = TheDoanhThuView(
            tieuDe: "📦 SỐ LƯỢNG & TỈ TRỌNG",
            mauBatDau: UIColor(red: 0.09, green: 0.61, blue: 0.27, alpha: 1),
            mauKetThuc: UIColor(red: 0.08, green: 0.50, blue: 0.24, alpha: 1)
        )
        the3.capNhatNoiDung(
            chinh: coDT ? soDon.chuoiSoNguyenVN : "--",
            phu: coDT ? "% TỈ TRỌNG: \(String(format: "%.1f%%", tyTrong))" : "% TỈ TRỌNG: --",
            coLon: true
        )

        let the4 = TheDoanhThuView(
            tieuDe: "📈 % HT THI ĐUA TB",
            mauBatDau: UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1),
            mauKetThuc: UIColor(red: 0.66, green: 0.33, blue: 0.97, alpha: 1)
        )
        the4.capNhatNoiDung(
            chinh: tongHop.phanTramHTTB.chuoiPhanTramVN,
            phu: "ĐẠT \(soMonDat) • CHƯA \(soMonChua)",
            coLon: true
        )

        let gap: CGFloat = 10
        let rongThe = (rongBang - gap * 3) / 4.0
        for (idx, the) in [the1, the2, the3, the4].enumerated() {
            the.overrideUserInterfaceStyle = .light
            the.frame = CGRect(x: le + CGFloat(idx) * (rongThe + gap), y: y, width: rongThe, height: caoKPI)
            the.layoutIfNeeded()
            khungBaoCao.addSubview(the)
        }

        y += caoKPI + 12

        let khungBang = UIView(frame: CGRect(x: le, y: y, width: rongBang, height: caoBang))
        khungBang.layer.borderWidth = 1
        khungBang.layer.borderColor = UIColor.systemGray4.cgColor
        khungBang.layer.cornerRadius = 8
        khungBang.clipsToBounds = true
        khungBaoCao.addSubview(khungBang)

        if let header = self.tableView(bang, viewForHeaderInSection: 0) {
            header.frame = CGRect(x: 0, y: 0, width: rongBang, height: caoTieuDeBang)
            khungBang.addSubview(header)
        }

        if dsMon.isEmpty {
            let lbTrong = UILabel(frame: CGRect(x: 0, y: caoTieuDeBang, width: rongBang, height: 50))
            lbTrong.text = "Chưa có môn thi đua nào trong mục này."
            lbTrong.font = .systemFont(ofSize: 12.5, weight: .medium)
            lbTrong.textColor = .gray
            lbTrong.textAlignment = .center
            lbTrong.numberOfLines = 0
            lbTrong.lineBreakMode = .byWordWrapping
            khungBang.addSubview(lbTrong)
        } else {
            var yDong = caoTieuDeBang
            for i in 0..<dsMon.count {
                let caoDong = cacCaoDong[i]
                let cell = self.tableView(bang, cellForRowAt: IndexPath(row: i, section: 0))
                let vDong = cell.contentView
                vDong.frame = CGRect(x: 0, y: yDong, width: rongBang, height: caoDong)
                let vach = UIView(frame: CGRect(x: 0, y: caoDong - 0.5, width: rongBang, height: 0.5))
                vach.backgroundColor = .systemGray4
                vDong.addSubview(vach)
                khungBang.addSubview(vDong)
                yDong += caoDong
            }
        }

        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2.0
        let anh = UIGraphicsImageRenderer(size: khungBaoCao.bounds.size, format: fmt).image { ctx in
            khungBaoCao.layer.render(in: ctx.cgContext)
        }
        bang.reloadData()
        return anh
    }
}
