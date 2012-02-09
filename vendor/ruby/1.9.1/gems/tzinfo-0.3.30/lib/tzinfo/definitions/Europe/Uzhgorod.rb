module TZInfo
  module Definitions
    module Europe
      module Uzhgorod
        include TimezoneDefinition
        
        timezone 'Europe/Uzhgorod' do |tz|
          tz.offset :o0, 5352, 0, :LMT
          tz.offset :o1, 3600, 0, :CET
          tz.offset :o2, 3600, 3600, :CEST
          tz.offset :o3, 10800, 0, :MSK
          tz.offset :o4, 10800, 3600, :MSD
          tz.offset :o5, 7200, 0, :EET
          tz.offset :o6, 7200, 3600, :EEST
          tz.offset :o7, 10800, 0, :FET
          
          tz.transition 1890, 9, :o1, 8681909177, 3600
          tz.transition 1940, 4, :o2, 58313293, 24
          tz.transition 1942, 11, :o1, 58335973, 24
          tz.transition 1943, 3, :o2, 58339501, 24
          tz.transition 1943, 10, :o1, 58344037, 24
          tz.transition 1944, 4, :o2, 58348405, 24
          tz.transition 1944, 10, :o1, 29176673, 12
          tz.transition 1945, 6, :o3, 58359251, 24
          tz.transition 1981, 3, :o4, 354920400
          tz.transition 1981, 9, :o3, 370728000
          tz.transition 1982, 3, :o4, 386456400
          tz.transition 1982, 9, :o3, 402264000
          tz.transition 1983, 3, :o4, 417992400
          tz.transition 1983, 9, :o3, 433800000
          tz.transition 1984, 3, :o4, 449614800
          tz.transition 1984, 9, :o3, 465346800
          tz.transition 1985, 3, :o4, 481071600
          tz.transition 1985, 9, :o3, 496796400
          tz.transition 1986, 3, :o4, 512521200
          tz.transition 1986, 9, :o3, 528246000
          tz.transition 1987, 3, :o4, 543970800
          tz.transition 1987, 9, :o3, 559695600
          tz.transition 1988, 3, :o4, 575420400
          tz.transition 1988, 9, :o3, 591145200
          tz.transition 1989, 3, :o4, 606870000
          tz.transition 1989, 9, :o3, 622594800
          tz.transition 1990, 6, :o1, 646786800
          tz.transition 1991, 3, :o5, 670384800
          tz.transition 1992, 3, :o6, 701820000
          tz.transition 1992, 9, :o5, 717541200
          tz.transition 1993, 3, :o6, 733269600
          tz.transition 1993, 9, :o5, 748990800
          tz.transition 1994, 3, :o6, 764719200
          tz.transition 1994, 9, :o5, 780440400
          tz.transition 1995, 3, :o6, 796179600
          tz.transition 1995, 9, :o5, 811904400
          tz.transition 1996, 3, :o6, 828234000
          tz.transition 1996, 10, :o5, 846378000
          tz.transition 1997, 3, :o6, 859683600
          tz.transition 1997, 10, :o5, 877827600
          tz.transition 1998, 3, :o6, 891133200
          tz.transition 1998, 10, :o5, 909277200
          tz.transition 1999, 3, :o6, 922582800
          tz.transition 1999, 10, :o5, 941331600
          tz.transition 2000, 3, :o6, 954032400
          tz.transition 2000, 10, :o5, 972781200
          tz.transition 2001, 3, :o6, 985482000
          tz.transition 2001, 10, :o5, 1004230800
          tz.transition 2002, 3, :o6, 1017536400
          tz.transition 2002, 10, :o5, 1035680400
          tz.transition 2003, 3, :o6, 1048986000
          tz.transition 2003, 10, :o5, 1067130000
          tz.transition 2004, 3, :o6, 1080435600
          tz.transition 2004, 10, :o5, 1099184400
          tz.transition 2005, 3, :o6, 1111885200
          tz.transition 2005, 10, :o5, 1130634000
          tz.transition 2006, 3, :o6, 1143334800
          tz.transition 2006, 10, :o5, 1162083600
          tz.transition 2007, 3, :o6, 1174784400
          tz.transition 2007, 10, :o5, 1193533200
          tz.transition 2008, 3, :o6, 1206838800
          tz.transition 2008, 10, :o5, 1224982800
          tz.transition 2009, 3, :o6, 1238288400
          tz.transition 2009, 10, :o5, 1256432400
          tz.transition 2010, 3, :o6, 1269738000
          tz.transition 2010, 10, :o5, 1288486800
          tz.transition 2011, 3, :o7, 1301187600
        end
      end
    end
  end
end
