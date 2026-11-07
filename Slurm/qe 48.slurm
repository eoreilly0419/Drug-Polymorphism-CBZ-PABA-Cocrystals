#!/bin/bash
#SBATCH --job-name=qe_scf
#SBATCH --partition=cpu           # change to short/long if needed
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=64      # try 16/32/64 depending on node cores & scaling
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00
#SBATCH --mem=128G                   # or request explicitly, e.g. --mem=64G
#SBATCH --output=slurm-%x-%j.out
#SBATCH --error=slurm-%x-%j.err

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
export UCX_TLS=sm,self            # single node: shared memory only, avoids the ibv_create_srq noise

srun --cpu-bind=none pw.x -in scf.in > scf.out 2> pw.stderr

# Optional: larger OpenMP stack for big FFTs/postproc (harmless if unused)
export OMP_STACKSIZE=512M

# ---- Inputs ----
# Ensure scf.in is in this directory and 'pseudo_dir' in your input points to your .UPF folder.
# Example: pseudo_dir = './pseudo'

# (Optional) follow-ups in same allocation:
# srun bands.x -in bands.in > bands.out 2> bands.stderr
# srun dos.x   -in dos.in   > dos.out   2> dos.stderr
