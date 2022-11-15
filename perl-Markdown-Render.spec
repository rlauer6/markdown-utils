Name:           perl-Markdown-Render
Version:        %{_version}
Release:        %{_release}
Summary:        Module for rendering HTML from markdown

Group:          Development Library
License:        GPLv2

Source1:        Render.pm

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:     noarch
Requires:      redhat-release >=  %{version}
Requires:      perl(Text::Markdown)

%description

This package contains the Perl mode Markdown::Render. A
module for rendering HTML from markdown using eithe the GitHub API or
Text::Markdown

%prep
%setup -q  -c -T

%build

%install
rm -rf $RPM_BUILD_ROOT

# yum
install -dm 755 $RPM_BUILD_ROOT%{_datarootdir}/perl5/Markdown
install -pm 644 %{SOURCE1}  \
    $RPM_BUILD_ROOT%{_datarootdir}/perl5/Markdown

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun

%files
%defattr(-,root,root,-)
%config(noreplace) /usr/local/share/perl5/*

