#!/usr/bin/perl
#Asahi.comクローラー

use utf8;
use strict;
use warnings;
use LWP::UserAgent;
use LWP::Simple;
use HTML::TreeBuilder;
use HTML::TagParser;
use NKF;

#日付の設定（コマンドから日付を入力or昨日の日付)
my $day;
if($#ARGV+1 != 1){
	$day = preDay();
}
else{
	$day = $ARGV[0];
}

sub preDay
{
	my $time = shift || time();
	my $prevDay = $time - (24 * 60 * 60);
	my ($yyyy, $mm, $dd) = (localtime($prevDay))[5,4,3];
	
	$yyyy += 1900;
	$mm += 1;
	
	return(
		sprintf('%02d%02d',$mm, $dd)
	);
}


#URLの設定
my $base = "http://www.asahi.com";	#asahi.comURL
my $level = "/news/daily/";		#階層
my $extension = ".html";			#拡張子

my $url = $base . $level .  $day . $extension;	#記事一覧ファイルurl
my $file_list = $day . $extension;
print "$url\n";

#webページの場合
#User::Agentの設定とHTMLの取得
my $user_agent = "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)";
my $ua = LWP::UserAgent->new('agent' => $user_agent);
$ua->timeout(30);
my $res = $ua->get($url);
if(!(defined($res))){
	print "Error Don't get list\n";
	exit(-1);
}
my $content = $res->content;

#プロキシの設定
#$ENV{'HTTP_PROXY'} = 'http://cache.st.ryukoku.ac.jp:8080';
#$ua->env_proxy;

#HTMLの解析
my $tree = HTML::TreeBuilder->new;
$tree->parse($content);

=pod
#ファイルの場合
my $tree = new HTML::TreeBuilder;
$tree->parse_file("$day.html") || die "Don't Open File : $!\n";
=cut

#記事リンクを含む行の検索
my @elms = $tree->look_down("class", "Lnk");
my $text = nkf("-w", $elms[0]->as_text);
my $html = $elms[0]->as_HTML;

#記事リンクの抽出
my @list = ();
my $temp = HTML::TagParser->new($html);
my @aelem = $temp->getElementsByTagName("a");
foreach my $elem ( @aelem ) {
	my $attr = $elem->attributes;
	foreach my $key ( sort keys %$attr ) {
		my $lnk = $attr->{$key};
		if($lnk =~ /\.html/){
			push(@list, $lnk);
		#	print "$lnk\n";
		}
	}
}

#記事の取得
if(!(-d "./Data")){
	mkdir("./Data");			#Dataフォルダがなければ作成
}
foreach my $line(@list){
	my @cut = split(/\//, $line);
	my $genre = $cut[1];		#ジャンル名の取得
	my $file_name = $cut[4];	#ファイル名の取得
	if(!(-d "./Data/$genre")){	#ジャンルのフォルダがなければ作成
		mkdir("./Data/$genre");
	}

	#ファイルの取得
	$url = $base . $line;
	my $sta = getstore($url, "./Data/$genre/$file_name");
	#die "Error $sta on $url" unless is_success($sta);
	print "$url\n";
}

open(FO, ">> ./Get_Day_Log.txt") || die "Don't File Open : $!\n";
print FO "$day\n";
close(FO);

#system("cp ./Data/Get_Day_Log.txt /media/share_hdd/Users/daisuke/Dropbox/ProgramFolder/4回研究/Crawler/Data/Get_Day_Log.txt");
