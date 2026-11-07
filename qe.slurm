#!/bin/bash
#SBATCH --job-name=qe_relax
#SBATCH --partition=cpu           # change to short/long if needed
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32      # 188-274 atoms: 32 cores is a reasonable start
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00           # raised from 1 h; override per job (see notes)
#SBATCH --mem=0                   # all memory on the node
#SBATCH --output=slurm-%x-%j.out
#SBATCH --error=slurm-%x-%j.err

# Usage:  sbatch qe.slurm NAME     (runs NAME.in -> NAME.out)
NAME="$1"
if [ -z "$NAME" ]; then
  echo "ERROR: give the input name without .in, e.g.  sbatch qe.slurm 729283"; exit 1
fi
cd "$SLURM_SUBMIT_DIR"
if [ ! -f "${NAME}.in" ]; then
  echo "ERROR: ${NAME}.in not found in $SLURM_SUBMIT_DIR"; exit 1
fi

# ---- Modules ----
module purge
module load openmpi/5.0.3
module load quantum-espresso/7.4

echo "Loaded modules:"; module list

# Sanity check
if ! command -v pw.x >/dev/null 2>&1; then
  echo "ERROR: pw.x not on PATH after loading modules."; exit 1
fi
echo "pw.x at: $(which pw.x)"

# ---- Runtime env (pure MPI, 1 thread per rank) ----
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1     # QE 7.4 here links OpenBLAS; avoid extra threads
export OMP_PROC_BIND=close
export OMP_PLACES=cores
export SLURM_CPU_BIND=cores
export OMP_STACKSIZE=512M

# ---- Run QE ----
srun pw.x -in "${NAME}.in" > "${NAME}.out" 2> "${NAME}.stderr"
