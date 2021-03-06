//
//  MTNotification.m
//  Vitality
//
//  Created by Andrew Salamon on 10/8/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "MTNotification.h"
#import "GlobalData.h"
#import "CCPDatabase.h"
#import "MTISKFormatter.h"
#import "METPair.h"

@implementation MTNotification

@synthesize notificationID;
@synthesize typeID;
@synthesize senderID;
@synthesize sentDate;
@synthesize read;
@synthesize attributedBody = _attributedBody;

static NSDictionary *idNames = nil;
static MTISKFormatter *iskFormatter = nil;

+ (void)initialize
{
    if( (nil == idNames) && (self == [MTNotification self]) )
    {
        idNames = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NotificationTypeIDs" ofType:@"plist" inDirectory:nil]] retain];
        iskFormatter = [[MTISKFormatter alloc] init];
    }
}

+ (MTNotification *)notificationWithID:(NSInteger)notID typeID:(NSInteger)tID sender:(NSInteger)senderID sentDate:(NSDate *)sentDate read:(BOOL)read
{
    MTNotification *note = [[MTNotification alloc] init];
    [note setNotificationID:notID];
    [note setTypeID:tID];
    [note setSenderID:senderID];
    [note setSentDate:sentDate];
    [note setRead:read];
    
    return [note autorelease];
}

- (id)init
{
    if( self = [super init] )
    {
        missingIDs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [sentDate release];
    [body release];
    [_formattedBodyValues release];
    [missingIDs release];
    [_attributedBody release];
    [super dealloc];
}

- (NSString *)body
{
    return [[body retain] autorelease];
}

- (void)setBody:(NSString *)newBody
{
    if( newBody != body )
    {
        body = [newBody retain];
        _formattedBodyValues = [[self formattedBodyValues] retain];
        _attributedBody = [[self formattedBody] retain];
    }
}

- (NSString *)notificationTypeDescription
{
    NSString *desc = [idNames objectForKey:[[NSNumber numberWithInteger:[self typeID]] stringValue]];
    if( !desc )
    {
        desc = [NSString stringWithFormat:@"Unknown EVE Notification typeID: %ld", (long)[self typeID]];
        NSLog( @"%@", desc );
    }
    return desc;
}

- (NSString *)tickerDescription
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDoesRelativeDateFormatting:YES];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"%@: %@", [formatter stringFromDate:[self sentDate]], [self notificationTypeDescription]];
}

- (NSString *)description
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDoesRelativeDateFormatting:YES];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"%ld %@ %@", (long)[self typeID], [formatter stringFromDate:[self sentDate]], [self notificationTypeDescription]];
}

- (NSArray *)missingIDs
{
    return [[missingIDs retain] autorelease];
}

- (BOOL)isWarRelated
{
    NSArray *warIDs = @[@(5),@(6),@(7),@(8),@(27),@(28),@(29),@(30),@(31),@(98),@(101),@(121),@(125)];
    return [warIDs containsObject:[NSNumber numberWithInteger:[self typeID]]];
}

/*
 Need to handle formatted data in notification bodies: https://eveonline-third-party-documentation.readthedocs.org/en/latest/xmlapi/enumerations/#notification-type
 See NotificationTypeIDs.plist for a list of all notification type ID's that we currently recognize.
 
 TypeID	Description	Structured Data
 1	Legacy	TBD
 2	Character deleted	TBD
 3	Give medal to character	TBD
 4	Alliance maintenance bill	TBD
 5	Alliance war declared	againstID: 00000000
 cost: 0
 declaredByID: 00000001
 delayHours: 24
 hostileState: 1
 6	Alliance war surrender	TBD
 7	Alliance war retracted	TBD
 8	Alliance war invalidated by Concord	againstID: 00000000
 cost: null
 declaredByID: 00000001
 delayHours: null
 hostileState: null
 9	Bill issued to a character	TBD
 10	Bill issued to corporation or alliance	amount: 20000000
 billTypeID: 2
 creditorID: 00000000
 currentDate: 130764012924912532
 debtorID: 00000000
 dueDate: 130789932230000000
 externalID: 27
 externalID2: 62300459
 11	Bill not paid because there's not enough ISK available	TBD
 12	Bill, issued by a character, paid	TBD
 13	Bill, issued by a corporation or alliance, paid	amount: 25000000
 dueDate: 130765575000000000
 14	Bounty claimed	amount: 8508.5
 charID: 90610935
 15	Clone activated	TBD
 16	New corp member application	applicationText: 'hey there, let me join!'
 charID: 90610935
 corpID: 00000000
 17	Corp application rejected	TBD
 18	Corp application accepted	TBD
 19	Corp tax rate changed	corpID: 00000000
 newTaxRate: 0.10
 oldTaxRate: 1.00
 20	Corp news report, typically for shareholders	TBD
 21	Player leaves corp	TBD
 22	Corp news, new CEO	TBD
 23	Corp dividend/liquidation, sent to shareholders	TBD
 24	Corp dividend payout, sent to shareholders	TBD
 25	Corp vote created	TBD
 26	Corp CEO votes revoked during voting	TBD
 27	Corp declares war	TBD
 28	Corp war has started	TBD
 29	Corp surrenders war	TBD
 30	Corp retracts war	TBD
 31	Corp war invalidated by Concord	TBD
 32	Container password retrieval	TBD
 33	Contraband or low standings cause an attack or items being confiscated	TBD
 34	First ship insurance	isHouseWarmingGift: 1
 shipTypeID: 596
 35	Ship destroyed, insurance payed	amount: 512304.80000000005
 itemID: 1017375674103
 payout: 1
 36	Insurance contract invalidated/runs out	TBD
 37	Sovereignty claim fails (alliance)	TBD
 38	Sovereignty claim fails (corporation)	TBD
 39	Sovereignty bill late (alliance)	TBD
 40	Sovereignty bill late (corporation)	TBD
 41	Sovereignty claim lost (alliance)	TBD
 42	Sovereignty claim lost (corporation)	TBD
 43	Sovereignty claim acquired (alliance)	TBD
 44	Sovereignty claim acquired (corporation)	TBD
 45	Alliance anchoring alert	allianceID: 00000000
 corpID: 00000000
 corpsPresent:
 - allianceID: 00000000
 corpID: 00000000
 towers:
 - moonID: 40009081
 typeID: 20062
 - allianceID: 00000000
 corpID: 00000000
 towers:
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - allianceID: 00000000
 corpID: 00000000
 towers:
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - moonID: 40009081
 typeID: 16213
 - allianceID: 00000000
 corpID: 00000000
 towers:
 - moonID: 40009081
 typeID: 27532
 - allianceID: 00000000
 corpID: 00000000
 towers:
 - moonID: 40009081
 typeID: 16214
 moonID: 40009081
 solarSystemID: 30000142
 typeID: 20064
 46	Alliance structure turns vulnerable	TBD
 47	Alliance structure turns invulnerable	TBD
 48	Sovereignty disruptor anchored	TBD
 49	Structure won/lost	TBD
 50	Corp office lease expiration notice	TBD
 51	Clone contract revoked by station manager	TBD
 52	Corp member clones moved between stations	charsInCorpID: 90610935
 corpID: 00000000
 newStationID: 60000004
 stationID: 60000007
 53	Clone contract revoked by station manager	TBD
 54	Insurance contract expired	endDate: 130739439920000000
 shipID: 1015328647115
 shipName: Tengu
 startDate: 130666863920000000
 55	Insurance contract issued	endDate: 130837996425414355
 itemID: 1018232075103
 level: 99.99999999999999
 numWeeks: 12
 shipName: Ishtar
 startDate: 130765420425414355
 typeID: 12005
 56	Jump clone destroyed	TBD
 57	Jump clone destroyed	TBD
 58	Corporation joining factional warfare	TBD
 59	Corporation leaving factional warfare	TBD
 60	Corporation kicked from factional warfare on startup because of too low standing to the faction	TBD
 61	Character kicked from factional warfare on startup because of too low standing to the faction	TBD
 62	Corporation in factional warfare warned on startup because of too low standing to the faction	TBD
 63	Character in factional warfare warned on startup because of too low standing to the faction	TBD
 64	Character loses factional warfare rank	TBD
 65	Character gains factional warfare rank	TBD
 66	Agent has moved	TBD
 67	Mass transaction reversal message	TBD
 68	Reimbursement message	TBD
 69	Agent locates a character	TBD
 70	Research mission becomes available from an agent	TBD
 71	Agent mission offer expires	TBD
 72	Agent mission times out	TBD
 73	Agent offers a storyline mission	TBD
 74	Tutorial message sent on character creation	TBD
 75	Tower alert	aggressorAllianceID: 00000000
 aggressorCorpID: 00000000
 aggressorID: 90610935
 armorValue: 1.0
 hullValue: 1.0
 moonID: 40009081
 shieldValue: 0.9999482233068171
 solarSystemID: 30000142
 typeID: 16213
 76	Tower resource alert	allianceID: 00000000
 corpID: 00000000
 moonID: 40009081
 solarSystemID: 30000142
 typeID: 20063
 wants:
 - quantity: 432
 typeID: 4312
 77	Station aggression message	aggressorCorpID: null
 aggressorID: null
 shieldValue: 0.9978610653837826
 solarSystemID: 30000142
 stationID: 60003757
 typeID: 28156
 78	Station state change message	TBD
 79	Station conquered message	TBD
 80	Station aggression message	TBD
 81	Corporation requests joining factional warfare	TBD
 82	Corporation requests leaving factional warfare	TBD
 83	Corporation withdrawing a request to join factional warfare	TBD
 84	Corporation withdrawing a request to leave factional warfare	TBD
 85	Corporation liquidation	TBD
 86	Territorial Claim Unit under attack	TBD
 87	Sovereignty Blockade Unit under attack	aggressorAllianceID: 00000000
 aggressorCorpID: 00000000
 aggressorID: 90610935
 armorValue: 1.0
 hullValue: 1.0
 shieldValue: 0.999942577300314
 solarSystemID: 30000142
 88	Infrastructure Hub under attack	aggressorAllianceID: 00000000
 aggressorCorpID: 00000000
 aggressorID: 90610935
 armorValue: 1.0
 hullValue: 1.0
 shieldValue: 0.9999601081022226
 solarSystemID: 30000142
 89	Contact add notification	TBD
 90	Contact edit notification	TBD
 91	Incursion Completed	TBD
 92	Corp Kicked	TBD
 93	Customs office has been attacked	aggressorAllianceID: 00000000
 aggressorCorpID: 00000000
 aggressorID: 90610935
 planetID: 40009081
 planetTypeID: 2063
 shieldLevel: 0.0
 solarSystemID: 30000142
 typeID: 2233
 94	Customs office has entered reinforced	TBD
 95	Customs office has been transferred	characterLinkData:
 - showinfo
 - 1375
 - 90610935
 characterName: CCP Guard
 fromCorporationLinkData:
 - showinfo
 - 2
 - 00000000
 fromCorporationName: Foo Bar Corp
 solarSystemLinkData:
 - showinfo
 - 5
 - 30000142
 solarSystemName: Jita
 structureLinkData:
 - showinfo
 - 32226
 - 1008433208457
 structureName: Some random POCO
 toCorporationLinkData:
 - showinfo
 - 2
 - 00000001
 toCorporationName: Bar Foo Corp
 96	FW Alliance Warning	TBD
 97	FW Alliance Kick	TBD
 98	AllWarCorpJoined Msg	TBD
 99	Ally Joined Defender	TBD
 100	Ally Has Joined a War Aggressor	TBD
 101	Ally Joined War Ally	TBD
 102	New war system: entity is offering assistance in a war.	TBD
 103	War Surrender Offer	TBD
 104	War Surrender Declined	TBD
 105	FacWar LP Payout Kill	TBD
 106	FacWar LP Payout Event	TBD
 107	FacWar LP Disqualified Eventd	TBD
 108	FacWar LP Disqualified Kill	TBD
 109	Alliance Contract Cancelled	TBD
 110	War Ally Declined Offer	TBD
 111	Your Bounty Was Claimed	TBD
 112	Bounty placed (Char)	TBD
 113	Bounty Placed (Corp)	TBD
 114	Bounty Placed (Alliance)	TBD
 115	Kill Right Available	TBD
 116	Kill right Available Open	TBD
 117	Kill Right Earned	TBD
 118	Kill right Used	TBD
 119	Kill Right Unavailable	TBD
 120	Kill Right Unavailable Open	TBD
 121	Declare War	TBD
 122	Offered Surrender	TBD
 123	Accepted Surrender	TBD
 124	Made War Mutual	TBD
 125	Retracts War	TBD
 126	Offered To Ally	TBD
 127	Accepted Ally	TBD
 128	Character Application Accept	applicationText: Hey, this is my alt.
 charID: 900000000
 corpID: 000000001
 129	Character Application Reject	TBD
 130	Character Application Withdraw	TBD
 138	TBD	cloneStationID: 60000000
 corpStationID: 60000001
 lastCloned: 130975015800000000
 podKillerID: 100000000
 140	TBD	killMailHash: aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
 killMailID: 00000000
 victimShipTypeID: 596
 141	TBD	killMailHash: a415ab5cc17c8c093c015ccdb7e552aee7911aa4
 killMailID: 00000000
 victimID: 000000001
 victimShipTypeID: 596
 147	Entosis Link started	solarSystemID: 30000142
 structureTypeID: 28159
 148	Entosis Link enabled a module	solarSystemID: 30000142
 structureTypeID: 28159
 149	Entosis Link disabled a module	solarSystemID: 30000142
 structureTypeID: 28159
 
 167    Self destruct   charID: 90683695
 corpName: Dreddit
 destructTime: 131048150327754976
 solarSystemID: 30000550
 structureTypeID: 32458

 168    Unknown        charID: 90683695
 solarSystemID: 30000548
 structureTypeID: 32226
 
 169    Unknown        solarSystemID: 30000585
 structureTypeID: 32458

 */

- (void)getCharacterPrefix:(NSString *)prefix fromLine:(NSString *)line values:(NSMutableDictionary *)values override:(bool)override
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    NSNumber *charID = [NSNumber numberWithInteger:[[line substringFromIndex:([prefix length]+2)] integerValue]];
    if( charID )
    {
        [values setObject:charID forKey:(override?prefix:@"charID")];
        NSString *name = [db characterNameForID:[charID integerValue]];
        if( !name )
        {
            name = [NSString stringWithFormat:@"CharID: %@", charID];
            [missingIDs addObject:charID]; // save it as a missing id, so some higher level can request them
        }
        [values setObject:name forKey:(override?[NSString stringWithFormat:@"%@Name",prefix]:@"characterName")];
    }
}

- (void)getTypeIDPrefix:(NSString *)prefix fromLine:(NSString *)line values:(NSMutableDictionary *)values
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    NSNumber *tID = [NSNumber numberWithInteger:[[line substringFromIndex:([prefix length]+2)] integerValue]];
    if( tID )
    {
        [values setObject:tID forKey:@"typeID"];
        NSString *name = [db typeName:[tID integerValue]];
        if( !name )
        {
            name = [NSString stringWithFormat:@"typeID: %@", tID];
            NSLog( @"Missing typeID: %ld", (long)[tID integerValue] );
        }
        [values setObject:name forKey:@"typeName"];
    }
}

// endDate: 131119703400000000
// startDate: 131047127400000000
- (void)getDatePrefix:(NSString *)prefix fromLine:(NSString *)line values:(NSMutableDictionary *)values
{
    NSInteger dateInt = [[line substringFromIndex:([prefix length]+2)] integerValue];
    if( dateInt )
    {
        dateInt = (dateInt / 10000000) - (NSInteger)11644473600; // Very bizzare data in Microsoft epoch format (starts on jan 1 1601)
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:dateInt];
        if( date )
            [values setObject:date forKey:prefix];
    }
}

- (NSDictionary *)formattedBodyValues
{
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSArray *lines = [body componentsSeparatedByString:@"\n"];
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    

    for( NSString *line in lines )
    {
        NSString *prefix = [[line componentsSeparatedByString:@":"] objectAtIndex:0];
        
        if( [prefix isEqualToString:@"charID"] ||  [prefix isEqualToString:@"victimID"]
           || [prefix isEqualToString:@"bountyPlacerID"] || [prefix isEqualToString:@"podKillerID"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:NO];
        }
        else if( [line hasPrefix:@"amount:"] )
        {
            NSNumber *amount = [NSNumber numberWithDouble:[[line substringFromIndex:8] doubleValue]];
            [values setObject:amount forKey:@"amount"];
        }
        else if( [line hasPrefix:@"bounty:"] )
        {
            NSNumber *amount = [NSNumber numberWithDouble:[[line substringFromIndex:8] doubleValue]];
            [values setObject:amount forKey:@"amount"];
        }
        else if( [line hasPrefix:@"killMailID:"] )
        {
            NSNumber *charID = [NSNumber numberWithInteger:[[line substringFromIndex:12] integerValue]];
            if( charID )
                [values setObject:charID forKey:@"killMailID"];
        }
        else if( [line hasPrefix:@"itemID:"] )
        {
            NSNumber *shipID = [NSNumber numberWithInteger:[[line substringFromIndex:8] integerValue]];
            if( shipID )
            {
                [values setObject:shipID forKey:@"itemID"];
                // this is an actual itemID, not a typeID. Not sure how to get more info about it.
            }
        }
        else if( [prefix isEqualToString:@"shipTypeID"] || [prefix isEqualToString:@"victimShipTypeID"]
                || [prefix isEqualToString:@"structureTypeID"] || [prefix isEqualToString:@"typeID"] )
        {
            [self getTypeIDPrefix:prefix fromLine:line values:values];
        }
        else if( [line hasPrefix:@"cloneStationID:"] )
        {
            NSNumber *itemID = [NSNumber numberWithInteger:[[line substringFromIndex:16] integerValue]];
            if( itemID )
            {
                NSDictionary *station = [db stationForID:[itemID integerValue]];
                NSString *name = [station objectForKey:@"name"];
                if( !name )
                {
                    name = [NSString stringWithFormat:@"StationID: %@", itemID];
                    NSLog( @"Missing stationID: %ld", (long)[itemID integerValue] );
                }
                [values setObject:name forKey:@"stationName"];
            }
        }
        else if( [line hasPrefix:@"solarSystemID:"] )
        {
            NSNumber *itemID = [NSNumber numberWithInteger:[[line substringFromIndex:15] integerValue]];
            if( itemID )
            {
                METPair *system = [db namesForSystemID:[itemID integerValue]];
                NSString *name = [system first];
                if( !name )
                {
                    name = [NSString stringWithFormat:@"StationID: %@", itemID];
                    NSLog( @"Missing stationID: %ld", (long)[itemID integerValue] );
                }
                [values setObject:name forKey:@"solarSystemName"];
                if( [system second] )
                    [values setObject:[system second] forKey:@"regionName"];
            }
        }
        else if( [line hasPrefix:@"corpID:"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:YES];
        }
        else if( [line hasPrefix:@"allianceID:"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:YES];
        }
        else if( [line hasPrefix:@"invokingCharID:"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:YES];
        }
        else if( [line hasPrefix:@"againstID:"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:YES];
        }
        else if( [line hasPrefix:@"declaredByID:"] )
        {
            [self getCharacterPrefix:prefix fromLine:line values:values override:YES];
        }
        else if( [line hasPrefix:@"campaignEventType:"] )
        {
            NSNumber *etype = [NSNumber numberWithInteger:[[line substringFromIndex:19] integerValue]];
            if( etype )
                [values setObject:etype forKey:@"campaignEventType"];
        }
        else if( [line hasPrefix:@"shipName:"] )
        {
            NSString *name = [line substringFromIndex:10];
            if( name )
                [values setObject:name forKey:@"shipName"];
        }
        else if( [line hasPrefix:@"endDate:"] || [line hasPrefix:@"startDate:"] )
        {
            [self getDatePrefix:prefix fromLine:line values:values];
        }
    }
    return values;
}

- (NSAttributedString *)formattedBody
{
    NSDictionary *values = _formattedBodyValues;
    NSString *plainString = nil;
    NSAttributedString *attrString = nil;
    
    if( [body length] > 0 )
        plainString = body;
    else
        plainString = [self notificationTypeDescription];
    
    switch( [self typeID] )
    {
        case 5: // Alliance War declared
        {
            NSString *name = [values objectForKey:@"againstIDName"];
            NSString *decl = [values objectForKey:@"declaredByIDName"];
            plainString = [NSString stringWithFormat:@"%@ has declared war against %@.", decl, name];
            break;
        }
        case 7: // Alliance War retracted
        {
            NSString *name = [values objectForKey:@"againstIDName"];
            NSString *decl = [values objectForKey:@"declaredByIDName"];
            plainString = [NSString stringWithFormat:@"War by %@ against %@ has been retracted.", decl, name];
            break;
        }
        case 8: // Alliance War invalidated
        {
            NSString *name = [values objectForKey:@"againstIDName"];
            NSString *decl = [values objectForKey:@"declaredByIDName"];
            plainString = [NSString stringWithFormat:@"War by %@ against %@ has been invalidated.", decl, name];
            break;
        }
        case 14: // Bounty payout
        {
            NSString *name = [values objectForKey:@"characterName"];
            NSString *priceStr = [iskFormatter stringFromNumber:[values objectForKey:@"amount"]];
            plainString = [NSString stringWithFormat:@"%@ bounty payout for killing %@", priceStr, name];
            break;
        }
        case 18: // Corp application accepted
        {
            NSString *name = [values objectForKey:@"corpIDName"];
            plainString = [NSString stringWithFormat:@"You were accepted to a corporation: %@", name];
            break;
        }
        case 34: // Free Rookie ship
        {
            NSString *shipTypeName = [values objectForKey:@"typeName"];
            plainString = [NSString stringWithFormat:@"Free rookie ship: %@", shipTypeName];
            break;
        }
        case 35: // Insurance payout
        {
            NSString *priceStr = [iskFormatter stringFromNumber:[values objectForKey:@"amount"]];
            plainString = [NSString stringWithFormat:@"%@ insurance payout for losing a ship", priceStr];
            break;
        }
        case 54: // Insurance policy expired
        {
            /*
             573331391|54|1000132|1469922720|1|endDate: 131119703400000000
             shipID: 1020842576611
             shipName: Which Witch?
             startDate: 131047127400000000
             
             Looks like the only way to get a ship type from the shipID is to use data from the AssetList API call.
             */
            plainString = [NSString stringWithFormat:@"The insurance on your ship named '%@' expired on %@", [values objectForKey:@"shipName"],
                           [NSDateFormatter localizedStringFromDate:[values objectForKey:@"endDate"] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
            break;
        }
        case 55: // Insurance policy taken out
        {
            // level: 99.99999999999999 = Platinum
            plainString = [NSString stringWithFormat:@"Your %@ was insured until %@", [values objectForKey:@"typeName"],
                           [NSDateFormatter localizedStringFromDate:[values objectForKey:@"endDate"] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
            break;
        }
        case 93: // Orbital Structure Attacked
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"attacked in"];
            break;
        }
        case 112: // Bounty placed on you
        {
            NSString *name = [values objectForKey:@"characterName"];
            NSString *priceStr = [iskFormatter stringFromNumber:[values objectForKey:@"amount"]];
            plainString = [NSString stringWithFormat:@"%@ bounty placed on you by %@", priceStr, name];
            break;
        }
        case 138: // Clone activated
        {
            NSString *name = [values objectForKey:@"stationName"];
            plainString = [NSString stringWithFormat:@"Clone activated at %@", name];
            break;
        }
        case 139: // Invited to Corp
        {
            NSString *name = [values objectForKey:@"corpIDName"];
            if( [name length] > 0 )
                plainString = [NSString stringWithFormat:@"You have been invited to join a corporation: %@", name];
            break;
        }
        case 140: // Killmail available
        {
            NSString *shipTypeName = [values objectForKey:@"typeName"];
            plainString = [NSString stringWithFormat:@"Kill Report - Victim\nYou lost a %@", shipTypeName];
            NSNumber *killID = [values objectForKey:@"killMailID"];
            if( killID )
            {
                NSString *zkillLink = [NSString stringWithFormat:@"https://zkillboard.com/kill/%ld", (long)[killID integerValue]];
                NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:plainString];
                [attStr addAttribute:NSLinkAttributeName value:zkillLink range:NSMakeRange(0, 11)];
                [attStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(0, 11)];
                attrString = [attStr autorelease];
            }
            
            break;
        }
        case 141: // Killmail available
        {
            NSString *name = [values objectForKey:@"characterName"];
            NSString *shipTypeName = [values objectForKey:@"typeName"];
            plainString = [NSString stringWithFormat:@"Kill Report - Final Blow\n%@ in a %@", name, shipTypeName];
            NSNumber *killID = [values objectForKey:@"killMailID"];
            if( killID )
            {
                NSString *zkillLink = [NSString stringWithFormat:@"https://zkillboard.com/kill/%ld", (long)[killID integerValue]];
                NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:plainString];
                [attStr addAttribute:NSLinkAttributeName value:zkillLink range:NSMakeRange(0, 11)];
                [attStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(0, 11)];
                attrString = [attStr autorelease];
            }
            
            break;
        }
        case 147: // Sovereignty structure capture started
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"capture started in"];
            break;
        }
        case 148: // Sovereignty Service Enabled
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"enabled in"];
            break;
        }
        case 149: // Sovereignty Service Disabled
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"disabled in"];
            break;
        }
        case 160: // Sovereignty Structure reinforced
        {
            NSAttributedString *dotlanLink = [self dotlanLinkForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"]];
            attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Sovereignty Structures are being reinforced in "]];
            // campaignEventType: 3
            [(NSMutableAttributedString *)attrString appendAttributedString:dotlanLink];
            [attrString autorelease];
            break;
        }
        case 161: // Command Nodes Decloaking
        {
            NSAttributedString *dotlanLink = [self dotlanLinkForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"]];
            attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Command nodes are decloaking in "]];
            // campaignEventType: 3
            [(NSMutableAttributedString *)attrString appendAttributedString:dotlanLink];
            [attrString autorelease];
            break;
        }
        case 162: // Sovereignty Structure Destroyed
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"was destroyed in"];
            break;
        }
        case 163: // Station entered Freeport
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"was freeported in"];
            break;
        }
        case 165: // Alliance Capital Changed
        {
            NSString *name = [values objectForKey:@"solarSystemName"];
            NSAttributedString *dotlanLink = [self dotlanLinkForSystem:name inRegion:[values objectForKey:@"regionName"]];
            attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ changed alliance capital to ", [values objectForKey:@"allianceIDName"]]];
            [(NSMutableAttributedString *)attrString appendAttributedString:dotlanLink];
            [attrString autorelease];
            break;
        }
        case 167: // Sovereignty structure self destruct
        {
            NSString *name = [values objectForKey:@"solarSystemName"];
            NSString *structure = [values objectForKey:@"typeName"];
            NSAttributedString *dotlanLink = [self dotlanLinkForSystem:name inRegion:[values objectForKey:@"regionName"]];
            attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Self destruct has been initiated for %@ in ", structure]];
            [(NSMutableAttributedString *)attrString appendAttributedString:dotlanLink];
            [attrString autorelease];
            break;
        }
        case 168: // Sovereignty structure Unknown notification
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"unknown notification (168) in"];
            break;
        }
        case 169: // Sovereignty structure Unknown notification
        {
            attrString = [self sovereigntyStringForSystem:[values objectForKey:@"solarSystemName"] inRegion:[values objectForKey:@"regionName"] structureName:[values objectForKey:@"typeName"] withText:@"unknown notification (169) in"];
            break;
        }
    }
    if( !attrString )
    {
        attrString = [[[NSAttributedString alloc] initWithString:plainString attributes:nil] autorelease];
    }
    return attrString;
}

- (NSInteger)rows
{
    NSInteger rows = 1;
    switch( [self typeID] )
    {
        case 14: rows = 1; break;
        case 34: rows = 1; break;
        case 112: rows = 1; break;
        case 140: rows = 2; break;
        case 141: rows = 2; break;
    }
    return rows;
}

/** Defaults to the system name as a plain attributed string (no dotlan link), if there is no region name
 */
- (NSAttributedString *)dotlanLinkForSystem:(NSString *)systemName inRegion:(NSString *)regionName
{
    if( 0 == [systemName length] )
        systemName = @"Unknown System";
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc] initWithString:systemName];
    if( systemName && regionName )
    {
        NSString *dotlanLink = [NSString stringWithFormat:@"http://evemaps.dotlan.net/map/%@/%@",
                                [regionName stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                [systemName stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
        [attStr addAttribute:NSLinkAttributeName value:dotlanLink range:NSMakeRange(0, [attStr length])];
        [attStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:NSMakeRange(0, [attStr length])];
    }
    return [attStr autorelease];
}

- (NSAttributedString *)sovereigntyStringForSystem:(NSString *)systemName inRegion:(NSString *)regionName structureName:(NSString *)typeName withText:(NSString *)text
{
    if( 0 == [typeName length] )
        typeName = @"Unknown Structure";
    NSMutableAttributedString *str2 = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ ", typeName, text]];
    NSAttributedString *dotlanLink = [self dotlanLinkForSystem:systemName inRegion:regionName];
    [str2 appendAttributedString:dotlanLink];
    return [str2 autorelease];
}
@end
