%global debug_package %{nil}

Name:		areditor
Version:	1.2
Release:	%mkrel 1
License:	GPLv3
Group:		Applications/System
Packager:	AKotov-dev
Vendor:		alex_q_2000
Url:		https://github.com/AKotov-dev/areditor

Source0:	%{name}-%{version}.tar.gz
Source1:	%{name}.desktop
Source2:	%{name}
Source3:	%{name}.png
Source4:	repack.txt
Source5:	%{name}.policy

BuildRequires:	lazarus >= 2.0.10
BuildRequires:	pkgconfig(gtk+-2.0)

Requires:	android-tools >= 31.0.2
Summary:	Automatic Rule Editor for Android devices

%description
ArEditor designed for automatically inserting rules for Android devices
that are not in the lists of rules /etc/udev/rules.d/51-android.rules
---
More information: /usr/share/doc/areditor/repack.txt

%prep
%setup -q -n %{name}-%{version}

%build
lazbuild --lazarusdir=%{_libdir}/lazarus --build-all *.lpi

%install
rm -rf %{buildroot}

mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/{icons,%{name},applications}
mkdir -p %{buildroot}%{_docdir}/%{name}
mkdir -p %{buildroot}%{_datadir}/polkit-1/actions

cp -f %{name} %{buildroot}%{_datadir}/%{name}/
cp -rf ./languages %{buildroot}%{_datadir}/%{name}/

install -m 0644 %{SOURCE1} %{buildroot}%{_datadir}/applications/
install -m 0755 %{SOURCE2} %{buildroot}%{_bindir}/
install -m 0644 %{SOURCE3} %{buildroot}%{_datadir}/icons/
install -m 0644 %{SOURCE4} %{buildroot}%{_docdir}/%{name}/
install -m 0644 %{SOURCE5} %{buildroot}%{_datadir}/polkit-1/actions/

%files
%defattr(-,root,root)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/icons/%{name}.png
%{_datadir}/applications/%{name}.desktop
%{_datadir}/polkit-1/actions/%{name}.policy
%{_docdir}/%{name}/*.txt

%changelog
* Sun Sep 05 2021 AKotov-dev <alex_q_2000> 1.2-1.mga8
- automatically adding a device description
- idProduct parsing in GOTO idVendor blocks
- adding idVendor and idProduct for missing devices
