Name: cookbook-cape
Version: %{__version}
Release: %{__release}%{?dist}
BuildArch: noarch
Summary: cookbook to install and configure cape in the redborder platform.

License: AGPL 3.0
URL: https://github.com/redBorder/cookbook-cape
Source0: %{name}-%{version}.tar.gz

%description
%{summary}

%prep
%setup -qn %{name}-%{version}

%build

%install
mkdir -p %{buildroot}/var/chef/cookbooks/cape
cp -f -r  resources/* %{buildroot}/var/chef/cookbooks/cape
chmod -R 0755 %{buildroot}/var/chef/cookbooks/cape
install -D -m 0644 README.md %{buildroot}/var/chef/cookbooks/cape/README.md

%pre
if [ -d /var/chef/cookbooks/cape ]; then
    rm -rf /var/chef/cookbooks/cape
fi

%post
case "$1" in
  1)
    # This is an initial install.
    :
  ;;
  2)
    # This is an upgrade.
    su - -s /bin/bash -c 'source /etc/profile && rvm gemset use default && env knife cookbook upload cape'
  ;;
esac

%postun
# Deletes directory when uninstalling the package
if [ "$1" = 0 ] && [ -d /var/chef/cookbooks/cape ]; then
  rm -rf /var/chef/cookbooks/cape
fi

%files
%defattr(0644,root,root)
%attr(0755,root,root)
/var/chef/cookbooks/cape
%defattr(0644,root,root)
/var/chef/cookbooks/cape/README.md

%doc

%changelog
* Wed Aug 06 2025 Pablo Torres <ptorres@redborder.com>
- Create cape cookbook
