#ifndef _OTP_H_
#define _OTP_H_

#include <xccompat.h>

//#define FAST_PROGRAM

// These should be defined in the top level xc file on a per core basis.
#if 0
#define OTP_DATA_PORT XS1_PORT_32B
#define OTP_ADDR_PORT XS1_PORT_16C
#define OTP_CTRL_PORT XS1_PORT_16D
#define TESTER_PORT PORT_1A
#define TESTINFO_PORT PORT_8A
#endif

/* OTP size in words */
#define OTP_SIZE 0x800

#define OTP_SECTORS 4
#define OTP_SECTOR_SIZE (OTP_SIZE / OTP_SECTORS)

#define OTP_SECTOR_0_START 0
#define OTP_SECTOR_1_START (OTP_SECTOR_0_START + OTP_SECTOR_SIZE)
#define OTP_SECTOR_2_START (OTP_SECTOR_1_START + OTP_SECTOR_SIZE)
#define OTP_SECTOR_3_START (OTP_SECTOR_2_START + OTP_SECTOR_SIZE)

/* Mode Register */

#define PROGRAM_VERIFY_SHIFT 6
#define PROGRAM_VERIFY (1 << PROGRAM_VERIFY_SHIFT)

/* Auxillary Mode Register A */

#define VPP_CHARGE_PUMP_ENABLE_SHIFT 12
#define VPP_CHARGE_PUMP (1 << VPP_CHARGE_PUMP_ENABLE_SHIFT)

/* Security register */

#define OTP_MASTER_LOCK_SHIFT 12
#define OTP_MASTER_LOCK (1 << OTP_MASTER_LOCK_SHIFT)

/* Lock status register */
#define LOCK_STATUS_MASTER_LOCK_SHIFT 8
#define LOCK_STATUS_MASTER_LOCK (1 << LOCK_STATUS_MASTER_LOCK_SHIFT)

#define SECURITY_CONFIG_ADDRESS 0x800

#define RO_SECURITY_CONFIG_ADDRESS 0x8000
#define MR_ADDRESS 0x8001
#define RO_AUX_MRS_ADDRESS 0x8002
#define LOCK_STATUS_REGISTER 0x8003
#define DISABLE_OTP_ADDRESS 0xffff

#define DISABLE_OTP_MAGIC 0x0D15AB1E

struct mode_reg {
  unsigned array_clear;
  unsigned pgmread1;
  unsigned pgmread2;
  unsigned normal;
};

typedef struct mode_reg mr;

struct otp_time {
  unsigned ref_time_tick;// = REF_TIME_TICK;
  unsigned tPP1_ticks;// = tPP_TICKS;
  unsigned tPP2_ticks;// = tPP_TICKS;
  unsigned tVPPS_ticks;// = tVPPS_TICKS;
  unsigned tPR_ticks;// = tPR_TICKS;
  unsigned tSD_ticks;// = tSD_TICKS;
  unsigned tACC_ticks ;//= tACC_TICKS;
  unsigned tACC2_ticks;// = tACC2_TICKS;
  unsigned tCD_ticks ;//=  tCD_TICKS;
  unsigned tRP_ticks ;//= tRP_TICKS;
  unsigned tRP_arrayclear_ticks;
  unsigned mr9;
  mr modereg;
  mr mra;
  mr mrb;
};

typedef struct otp_time otp_timing;

struct OTP_Options {
  /** Non zero if charge pump should be enabled, zero otherwise. */
  int EnableChargePump;
  unsigned weak;
  unsigned differential_mode;
  /* Any other options go here... */
  otp_timing timing;
};
typedef struct OTP_Options Options;

struct redundancy_byte {
  unsigned address_offset;
  unsigned inuse;
  unsigned towrite;
};

typedef struct redundancy_byte red_byte;

struct red_array {
  red_byte redundant_bytes [4];
};
typedef struct red_array redundancy_array;

#ifdef __XC__
/** Initialise all options with their default values. */
void InitOptions(Options &otp_opts);
void WriteModeRegister(out port otp_data, out port otp_addr, out port otp_ctrl, unsigned value);
void WriteAuxModeRegisterA(port otp_data, out port otp_addr, out port otp_ctrl, unsigned value);
void WriteAuxModeRegisterB(port otp_data, out port otp_addr, out port otp_ctrl, unsigned value);
unsigned ReadModeRegister(in port otp_data, out port otp_addr);
unsigned ReadAuxModeRegisters(in port otp_data, out port otp_addr);
unsigned ReadAuxModeRegisterA(in port otp_data, out port otp_addr);
unsigned ReadAuxModeRegisterB(in port otp_data, out port otp_addr);
int Program(timer t, port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, const unsigned data[], unsigned size, Options &otp_opts);
void Read(timer t, port otp_data, out port otp_addr, out port otp_ctrl,
          unsigned address, unsigned data[], unsigned size, Options &otp_opts);
#endif

typedef enum {
  MARGINS_READ_1,
  MARGINS_READ_2,
  MARGINS_DEFAULT,
  MARGINS_ARRAY_CLEAR,
} OTPReadMargins;

#ifdef __XC__
void ReadMargins(timer t, port otp_data, out port otp_addr, out port otp_ctrl,
                 unsigned address, unsigned data[], unsigned size,
                 OTPReadMargins margins, Options &otp_opts);
void ReadMargins2(timer t, port otp_data, out port otp_addr, out port otp_ctrl,
                  unsigned address, unsigned data[], unsigned size, unsigned mr,
                  unsigned mra, unsigned mrb, unsigned read_pulse_ticks,
                  Options &otp_opts);
unsigned ReadWord(timer t, in port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, Options &otp_opts);
unsigned ReadWordTimed(timer t, in port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, unsigned read_time_ticks);
unsigned ReadWordBootRom(timer t, in port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, Options &otp_opts, unsigned read_time_ticks);
unsigned ReadSR(timer t, port otp_data, out port otp_addr, out port otp_ctrl, Options &otp_opts);
/** Read the redundancy register. Always returns 0 on XS1-G. */
unsigned ReadRR(timer t, port otp_data, out port otp_addr, out port otp_ctrl, Options &otp_opts);
// returns address of lowest unprogrammed row (ie 0 for blank array),
// or -1 for error.
int ArrayClear(timer t, port otp_data, out port otp_addr, out port otp_ctrl, unsigned addr, unsigned size, Options &otp_opts, unsigned failmap[]);
void init_timing_opts(otp_timing &timing);
void ClearModeRegs(timer t, port otp_data, out port otp_addr, out port otp_ctrl);
void SetPGMRead1(timer t, port otp_data, out port otp_addr, out port otp_ctrl, Options &otp_opts);
void SetPGMRead2(timer t, port otp_data, out port otp_addr, out port otp_ctrl, Options &otp_opts);
void SetArrayClear(timer t, port otp_data, out port otp_addr, out port otp_ctrl, Options &otp_opts);
// L1 only.
void WriteQ_RR(port otp_data, out port otp_addr, out port otp_ctrl, unsigned value);
void WriteQ_SR(out port otp_data, out port otp_addr, out port otp_ctrl, unsigned value);
void InitialWriteWord(timer t, port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, unsigned value, Options &otp_opts );
int WriteWord(timer t, port otp_data, out port otp_addr, out port otp_ctrl, unsigned address, unsigned value, Options &otp_opts );
int RepairLeakyCells(unsigned address, unsigned size, unsigned leakymap[], const unsigned data[], redundancy_array &red);
int CheckLeakyCells(unsigned address, unsigned size, unsigned leakymap[], const unsigned data[]);
int RedAvailable(redundancy_array &red, unsigned address);
#endif

struct OtpStats {
  unsigned programmedWords;
  unsigned programmedBits;
  unsigned soakedBits;
  unsigned leakyBits;
  unsigned failedToProgramWords;
  unsigned redundantSectorsUsed;
};

/**
 * Write the current OTP statistics into the specified structure.
 */
void GetOtpStats(REFERENCE_PARAM(struct OtpStats, stats));
void MergeOtpStats(REFERENCE_PARAM(struct OtpStats, a), REFERENCE_PARAM(const struct OtpStats, b));
void PrintOtpStats(REFERENCE_PARAM(const struct OtpStats, stats));

#endif /* _OTP_H_ */
