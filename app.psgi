use strict;
use Cwd;
use File::Basename;
use Plack;
use Plack::Request;
use Plack::Builder;
use Template;
use utf8;
use Encode;

# legal   = Юридическое лицо
# natural = Физическое лицо
my @list = (
    { id => 1, type => 'natural', name => 'First User',     inn => '024800000001' },
    { id => 2, type => 'legal',   name => 'First Company',  inn => '024800000002', address => 'Moskow 1' },
    { id => 3, type => 'natural', name => 'Second User',    inn => '024800000003' },
    { id => 4, type => 'legal',   name => 'Second Company', inn => '024800000004', address => 'Moskow 2' },
    { id => 5, type => 'natural', name => 'Third User',     inn => '024800000005' },
    { id => 6, type => 'legal',   name => 'Third Company',  inn => '024800000006', address => 'Moskow 3' }
);

my $newItemId = 7;

my $root = Cwd::realpath( dirname($0) );

my $tt = Template->new({
    INCLUDE_PATH => "$root/tt"
});

sub render($;$) {
    my ($template, $vars) = @_;
    my $output = '';
    $tt->process($template, $vars, \$output)
        || die $tt->error(), "\n";
    return $output;
}

sub build_app {
    my $param = shift;

    return sub {
        my $env = shift;

        my $req = Plack::Request->new($env);
        my $res = $req->new_response(200);
        $res->header('Content-Type' => 'text/html', charset => 'Utf-8');

        my $body;
        if ($param eq 'index' && $req->path_info() eq '/') {
            $body = render('index.tt');
        }
        elsif ($param eq 'list') {
            $body = render('list.tt', {
                list_name => encode_utf8('Список элементов'),
                list => \@list
            });
        }
        elsif ($param eq 'edit') {
            my @path = split '\/', $req->path_info();
            my $id = @path[1];
            if ($id eq 0) {
                $body = render('form.tt', {
                    form_name => encode_utf8('Добавить элемент')
                });
            } else {
                my ($item) = grep {
                    $_->{id} eq $id
                } @list;
                $body = render('form.tt', {
                    form_name => encode_utf8('Редактировать элемент'),
                    item => $item
                });
            }
        }
        elsif ($param eq 'save') {
            my $formData = $req->body_parameters();
            if ($formData->{id}) {
                my ($itemIdx) = grep { @list[$_]->{id} eq $formData->{id} } (0 .. @list-1);
                if ($itemIdx != -1) {
                    @list[$itemIdx] = $formData;
                    $body = render('form.tt', {
                        form_name => encode_utf8('Редактировать элемент'),
                        form_msg => encode_utf8('Элемент успешно изменен'),
                        item => $formData
                    });
                } else {
                    $body = 'item not found';
                }
            } else {
                $formData->{id} = $newItemId;
                push(@list, $formData);
                $newItemId++;
                $body = render('form.tt', {
                    form_name => encode_utf8('Редактировать элемент'),
                    form_msg => encode_utf8('Элемент успешно создан'),                    
                    item => $formData
                });
            }
        }
        elsif ($param eq 'delete') {
            my $formData = $req->body_parameters();
            my ($itemIdx) = grep { @list[$_]->{id} eq $formData->{id} } (0 .. $#list);
            if ($itemIdx != -1) {
                splice(@list, $itemIdx, 1);
                $body = render('list.tt', {
                    list => \@list
                });
            } else {
                $body = 'item not found';
            }
        }
        else {
            $body = render('base_error.tt', { status => 404, text => 'Page not found' });
        }

        $res->body($body);

        return $res->finalize();
    };
}


my $main_app = builder {
    enable 'Static',
	    root => "$root/static",
        path => sub { s!^/static/!! };

    mount '/list'       => builder { build_app('list') };    # get  данные списка в массиве
    mount "/edit"       => builder { build_app("edit") };    # get  данные в хеше item (item.id, item.name, item.inn и т.д.)
    mount '/save'       => builder { build_app('save') };    # post соответствующие поля передаются в виде переменных формы
    mount '/delete'     => builder { build_app('delete') };  # post передается поле ID
    mount '/'           => builder { build_app('index') };   # get  base.tt
};
