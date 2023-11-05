#if defined _VIP_FreeVIPGiveaway_included_
  #endinput
#endif
#define _VIP_FreeVIPGiveaway_included_

/**
 * Returns whether the freevip is on or not.
 * *
 * @return     True if ON, false otherwise.
 */
native bool FreeVIP_IsFreeVIPOn();

/**
 * Returns the FreeVip End Timestamp.
 * *
 * @return     Value of End Timestamp
 */
native int FreeVIP_GetEndTimeStamp();

/**
 * Returns the FreeVip Start Timestamp.
 * *
 * @return     Value of Start Timestamp
 */
native int FreeVIP_GetStartTimeStamp();


public SharedPlugin __pl_FreeVIPGiveaway = 
{
    name = "VIP_FreeVIPGiveaway",
    file = "VIP_FreeVIPGiveaway.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
}

#if !defined REQUIRE_PLUGIN
public void __pl_FreeVIPGiveaway_SetNTVOptional()
{
    MarkNativeAsOptional("FreeVIP_IsFreeVIPOn");
    MarkNativeAsOptional("FreeVIP_GetEndTimeStamp");
    MarkNativeAsOptional("FreeVIP_GetStartTimeStamp");
}
#endif
