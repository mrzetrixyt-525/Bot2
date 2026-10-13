#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 077

if [[ "${1:-}" == '-h' || "${1:-}" == '--help' ]]; then
  printf 'Usage: sudo bash node.sh [--api-key KEY] [--prompt-api-key] [--port 18443] [--host 127.0.0.1]\n'
  exit 0
fi

# RGNODES™ compact remote-node installer. The node agent and KVM controller are
# embedded and SHA-256 verified; no sidecar source files are needed in the bundle.
NODE_AGENT_ZLIB_B64='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'
NODE_AGENT_SHA256='99b8afb52d5318e344bac50288afc788e5f23c51fa559ba9e15ff1c5d6d955e6'
VPSCTL_ZLIB_B64='eNrdfdt220iS4Du/AqXqXhA2eJEsu6spwzMqW3Zpy7I9slzds7KGBZGgiBYJwACoy7B5zjzsH+x+wX7afMnGJTORiQtJuVx9dtZ1ygaBzMhbZGREZFy+/663yNLeZRj1gujGSu7zaRw9ae3s7Jy+eff+1dHH//yf/8f65cNHaxRHeRrPZkFq/ed//G/r519Oev9ydPKpNwsvb8I0t+Jodt9ttc6mgfUqzEZxOrYu49wa+bNZZuXw9tdRPE/8/FcrjPIgnfijwMpiK8wza+7nizSAFuZzPxpb2YK/jvzISoO5H0atLPcvZ4F1Ow3hbwTmj/KFP6OOpYsoD+eBFWaWD+XhLfTNwj5hibk/moZR0LWwY9oYgrskzoKMuk1g4iRI/TyMo6yLo29N0nhuDYeTBfZtOLTCeRLDMP0oinMu15Kv0qvET7PAtS79LHi271pTP5vCvLhWmPjjcRpkmWv9LYsj14rhKYWSWTBKgxx+QMHgDv9Z5OEM/o1H10EO/y4ukzQeUc3sHv7Kg3kygdHDEwyWewezic3Irn2An/xhkc7gfTcNviyCLJffT/mni59htBGXxTkJ7nINjngDa+FfBWkrT+8HLQv+iM+TUZTPWsHdKEhy65jeHaVpnHIh+mp51rs4Clqt0/fvz+AH9qwdZ92rIAcka9sCtYYw70MsYruW3bvxU0SmXnoVxeMg69wkme04rbfvX/48fH389gjgELieZXeLhezOYMbs1vHJ4Zuj4avjU9d6dfzxZ376eHT0Sj69PD064+eTo7NDfAJ45wLgnTWJU/g7jKy2Hc5h2Jnt2uMwu8Z/syAY87+0ZvA0D3Lfdi5a747O/vL+9GeAVDM4wMKhKIDjk8NKFpezcGQ73SxPw6TtWNBy+aMEPDwBSCZ0DSp9RdDjMA1GeQES5uQ2SNtO68fT41dvSgA+fPrx7fHLIX8avjs8IRBF5daHw9Ojd2fD49e19eTXd2dHp68PX5Yrnx4dvh2KoqdH//Lp+PToVWl6tBLHH37ZV8VgXvN0EVSHgcuytHfld9e+p+WJI3vVkr16//5tbXepBfw6fHn86rQ8Ui7z5vDs6C+H/9pcXxSor/3q3UfEpDu1ngqVGqBBBej9bpf+c3/o0n8IN5mFeRs+wYAnloIHWPb6bHh2+OPbo3o8U581LBvS5qlDMfrSOnx3djw8OX53/O6NCVT7MDx6h1C/bl1a42BiDQHkEKh9O/LnQLjglb+Y5Q4TCiQrQAqBukZ4IrQBuEYizBqqaYeqCtrTPrtPAiI9rvWLP1vws2NAlRC0Dk1msd/cJXrAPzcI0ePCD+gbEcoJ17a+88QDLAA/IIVhmHYYTWzHFT869Av77odZoA2nbUdx1JmEUZjDEqgmxBAJ6OY5ca33N3DkwrqVpohbLybp5PCvw9PDE8CJuX/X3nWteRi1f3CLlbSxBJHtw5Phmx9t9wcHBo4vX374VFSrlofPVLgFyDVEEi0KPzUKwzcsTCQcoe/2BXSthgRQ14pWEWsCHp8dA7mpDEmMUwchy+qD23U0IMYAJRB42QSERmxAqB2EhFQekg7KmA+n9dP7j2fUx9Ojj0envxzBJwG235XzKfCqpqjt7kkYBLcCZK/brwFSKivWhj7BSOUX2Q99JOUyNCtc8xd8/f6Xo9OX709OjrGnZ8fv1Vj+9JSnp75DtXUBdvepRMlXRx/evv9XGv7Hn+DcUoB3+wy43/1zCXJdNdvtd38oJh6b1Yp9eHkmUbnfFXD//LS2x9WasCWgqCO2hVqs16dHR/hZlJTwJXhuyOj2mtowJT9wG8wkfTp9iyfWsmXZi0vgnReDPYC3bw/saZ4n2aDXG83ixbjDfFCXywDHNe+lwSwADjfrZUEK9KQ3iYG7l297XLBDwDpcokOQwvlVx5+Pn+134cl2tXb3vq7dv/nz+X2l3b3t293/unajGISQSrv7m9sdB5ehHw12d8uNdvlLN06vetw+v+9dLkBsCu6D3szPgWfvcbnO7m7nKoiCNBxxn7mZL6P4ds9oaG/7huL4+jZO5+WG9rZr6MnWDcEheRdWxvNkXTOr1uHb48OPRx+9pVw6Qjlo08BcV/4kxNC+7hlfafm0r/v8lXs54B71aI2K9ap83tM+71U/P9E+P5F80DgM2vPsCiS/kbcLh2+SIl2kNyjSeSDgARMxDtLUORAMwMf7DCS+ozvgCNORQ1BAzm2DqHnDEmC8yL3dPSADo2kwuvbOgAMDcTNKFvlw7Oe+h/KXYGsSr5AmuwoKlfWKGi7KfAwH+oLgtVofjj8cudzFymvZG/Ev8yjAAlHHLBToky6zGyNgQL/z+gWPNQY5Kpx57UQMX2dY6R3A099N7ABmxFrqAFe2cz7Ye9rvXxTMEU3hKesFmIua7CxtkBv/FgP5nPsJcnQuToPjrAbWkvux2uG+C94o4cULogwVACBjZW0xocjhJ8TKofzoFrKnEj2V5KkJnlLudIrxJ935NQBuJ34aRHnGsw9DzPJhzGvKPQLeczSdx2Nurx//Cbgb84PWjvjc+ueSHI+DKeTmIcrNckA7OzsfYRP6s/DfA2u+QP1GdKVpRFBRkwZZvEhHQe/4g+XPoDZ9QiVNFOcw5aOgi2oT4kX1KeMZm6KYkQRRW4nzIKz4jwVHazDegDqsRAgzC0EjJhdflY6hO6ERTKZd3ENR3HZc8YGaOPprwSzfh8FszP0II+i71pjR8natb9uDT++KHlTa5UnpAtXLgraQTsJsiOqrISsBhmFys98mBr9YpcMRcflXs/gS4VkpbBDSjB1/uNm3FlE48rPcEjonqd1qRwGcTbCus5y+wwlGx9XYUStmLkDiKb1VN0yG4pGkIO5PVeQRe6YdJl1oK0PM8Dxrn7Y/vIOhcZ/pBc4rv1R9qsywWU72uPR6EWVJMAonYTDeAGAWx8mlL+iR9jqMrnEn+DNDsiwkp0F5hK99OJd5vW79MB8CLTAWjIVDRaGBb1SL9xcoT7RDqCnFvMIP1KHB4C7vSbd5xUq7PAtmkwOLFw8kbHinpgEVUEi0LT+D0ySOJ2olx4E/hlEFRI67+FfbeUxcfd/FU0dSaR7vDKaejgr6JdSrRcXnEloxDVSDejiU/a6M35CEZ4SRiAY16I0fHXNXiHme6UhBXcpmQZC0n8iFgoWHtj3bLrQJ6iViakGjhqjnHOKUce9Qjm/bWjds1pDYBg4c0T9QHc5rP8ta2nk1sa22XApvKVtduTxWmpyOWlRuhzaot6QC0NYOCPXBzsqxcYYkACsA1LIQ+MPhtBrOvYIC7aCSe4kTsAKGhDdBGoyC8CYAhAQco23EmKm1Zd2G+RQVPQJxVpk8LbvWjoJuo3Zd4rOgnP4YgObQozFiqT/KoaWu9ZK4AsDZmxBOfCJgAXChaTi+CgDXc+BFr+HwccUuePXTyw+SP4/C3LXwzsF6Q98OgXWEN4hbDcrJXq0WsMuzJaguULQQtlIwxKlhBGGExEfCJHwQCKKUfwK5eRK7E+DW534+mrZT+/yw8z/8zr/3O3++KB67w87Fsu8+669sl5uoWyz7OKLe0H0EFrMNhgTfcJ8jYNjpsB7GWftG9PeGOntT6qlU1h1IKIKlpk1w497IswfZ2GHCevqhfupcB/ee0Z76LicBSjBJjaxCwqwd4MT+BKxBIjD6/UduFhgwCXNljlhxVj3Yb11gPHF+/82Y1cfAgw9tF/rgPLZJ4BIjGse3EQjH4yG1UR7VGBDIqxu0HBQW6BIrBjwM4Ri9yYA3auPkDjOYjhd7j3b7e/v0l9KpYTmCskhnXjEh5/WTyFxrPk88go+7bZgtJpPwrm135RjsgloPA5zJgmYbJzcdLjleFdFqpH4EI9919ysk9osnLoPa0El3ClQeDm2Qsj4BUevQvgI5RiiYO4CNnZeKcQQRqLtnrxwDYoWNwj/f050b32jJE9Hyk2QWAmeSx9bZ2489YEgjIH58QETjEKgC3toBFRobN3JV2IdA32+tDP/S5HdrHuL8ZAQQFiSFIxWmIQthSNYUXmZT/zroCUJjTYCQAata0wAuhLwoA+T74upHOhK01GWGFpbOtW8vbXo5qc5CcbAiP1//Hf9cemkXh91WGOU0lhWU53JgXUKV68Zyk+5tGuZB+7IKCkBAz0v4/NzTEboWbB3ZeiXQFPY0LQVvazwHFpE83IAPzQD9Z3a1KyDEwCk3AwmCJhP3AZArJdrgbxBqnu3vF0RM7TH5R6q/338UCm+9h7Q0UKI6Im1HwffKZ+IqcJoWEXKK7WrfRbuvYX3fxfnreBGNmW8smIbSrIv9+fxJ/fxqrM7+I1HWWSfZmiKFLYmqon+E43gGT3I4b5/I9gFX8fZ3CSgOJ7ldgvIW+YuAB7LM75OgXcyU0x3SWTkcouhcvK+Asfmsh01zifNi/XR2hvfskXUGZ/r+/hPXwrszlCtnC9zmLrIFd/e9SZgGt4AqVrqYBZlbbOVuAd+pF+cEVku6PWhtv5oNbB+dJXzzyyeFPL4ZEQu5uzexlzW8xKrLlW0ChExoHRipG2gEgtYDDCLzb4Ihw2RhA7sJxGwM0Cr95P0/RDUAiW+qrBug8gQYLc9e5JPOD7a+4ypgcPuhToHUUECj9PYLJVO5ls4kaWtSzxggy8MQgGj4N4CzJNfiicZMq8kZJEQreWCVoSgujTrcLAjInpdWRW8H572L2yhr6006dEdbDIpZ96XQ901j2BMjP/FHYX4/jK/bqT8fXl26o2TholEBPluPXBzcEEYMay30d4CDs8WYV17X4M2DuUc2FHYPVW89+B1GkxhGqs0CnXueHV4BoyE5xzzOQeK6vvTUjOKPvtJioWyHnAIA5PtnfGFsHJTg0H4GDoo0z/BUbNsnwfwMAQ9sWE3VBEqXXJQusp3z3YtihwWzBkCHsmMEzOhmI0BukifVk+338Myiv4gKiLe8MP2uGHIaBLKe3pRZV/9i1ocFHBJkD/cK/BgBYctZN7kr0IbFQmzFg2oHxRsor8084RzqjXD65fbvopKkbT/i7e6sUVPNPQ0zFSwDQ8tqLR25iKYiQZizMMzChuORCKEXhDVBnWEYiWvmgoUsxmk99sRFsoCGMzwL52EO82y7fZqevlNfH2YF65NCnGvjvFLtmqoVIm0ANXqa+RNe68sFiJY53qGFUXFa8kVg3zWQyepYNRemjruh1iOr7tpQVHMKdBTFDZQKJ6W5FFPJZR3rRXkgg7Vqbhuvuv3xPMxIBzcOIhDqB5riyL8D9sBa6m0OuruTlfUm/BEaj4Jb+Eht8yuc8WBMWqactRRI3Swxqcty5xQoqSAhTFvWzc+g2//jysL+Aql0BMHCxS8WjO/aETfUzoPJbr79deQCarfNNP9FdZ78ytQTGsqWcNaLjmyYcDQLeMiEA+CVnGh6rs7wDcKUM1x0ZAWTiueYtWyegUF3b7IawKTRKsk1WJYnZSXn+3vrJz8dA2W+CTqLDPnGqwW8yCxUlmZ5nJBGkuGwwl/063YaRPSNGkLbyxkSn3v4nt13hTpqPiSKm4xwNdsa9bV65R2024cd0bBX6JtcsuLQJNQyShOnqLf63Fp3M77FVkpQo4XGqTQtYnnhn2QW389Bphywin2pt0qb4I88MQgDJ0ceKXgefFkAg5vBpljXtW4fYSBI22kYeoHU+KvJNuE5Tl8xUhDKb2Mrm6IlZxb5CTyBLHAN8oblQ5dz7jbJBj5dNuBN0Bw4CosE5vEixRekv0OEhx9d7TpvYg2Z+YGuSehlNpwkaxKdBTeDMqjt2qldZUpRcEOpfVZ3BxOj+vAWz8+mInKXx7cG24Gb3XaaRXHSzGTeOZKDO82gj+BIXmRwcdEsn0NvPIZy/uTicVs87l8QOwUj5xfOi31Bj5pFfcGHZou5rOQi9DqVed/tFwzDrhvuenWLcaCLmGgKg2/23HCvtnSxtjmwrl6+10HIe51wV33BCoD1njwb8ZilHeu2x3lnHDqP6FdvnDPXPM5f9M0zUF4YMyDrhdeEzCU1VhM53rxpCcmxKOzNpWhXbNtFFoxhRqYAYxrPxhrtLPWFdqjYnEQ6PTbi7hKLT2/ovtYpWE/84tGXLv7usa7n0ROdrdXK0ItSIXWOUDnF2P5/xFHiwCosJc3pGp7yAYyhOmepJXG2KuwtFqFTZ/bmVDgH7q60pGTpDhmI2mY2nDivENZDmAkEXWHfRCdM/o0wXsqk1rK+dwoSK4tEM9oBJJEYThXc5jxo3bxRGrTKiXCgU3XzuGEijiPSgY9IbRvO58E4xFOPBkHto8o6jeO5PH9Vz4oxlM5Ojfmo6zycwbLvgvV2vq6PeOLL3tG+JM0Gnj6LxOgtN6PNueQR5A2GuKFM4ng2JN5KnqQwHM3ufc2ejgCxjat8ofdua9VdVJYA+aaL7cqGKm7Ca3WoDRPDt1i1l28DawlQVnC0E4+ha11RVRTk0n7gO2+//pKsFqw1x/vxSzaEsI0LaFQ/mZb+m+FKl4Awk/zamDne+sahGJCYSXgFh85Ya72yIFeAIbf+fb19hdnJ320p1CSsWwjRUWXM8Z1n7W8/bc2LIeDK+0JY7wctRrzIs3Ac1C+D2VKtJwoeUm1qu8YYAZFPbBC5Js18WekKI7XWQb1M4VRFM5dvCFfMpONsRIOGHaPdm1cXD7igGisj3S6gYmzksqI3DUFQRA+3qQ+bwS3Mjlx1jrmWNMdxcYTjeLRAtozlS7q0zLS1/N566c9GCzQcRT4L+tHhwwx1b5afAksP7Eo4opsA9CUUlmwop8zCLKcVwBoZqm1HfqRBFrrhwLoMZzOydIsnVnz5NzgaM2GqM0dnRrm3rV6fRa/Uz6aF+CvtIRVk7icx1JlHeLWYDwuzLEHpgE+dhHcgDyDL+2SXmeJK6c6ejtY65Od7D6GQIV66xnwLdyAtMCw/t9CcObcA7wVwXl/VftXrBJXV8iAyPNXIIYhtOch/jtzSVrzrhC8azKlyMCvuP3SIdRu3fpynZVsVnVxfLnJASPmZO9VjQ0vNAzWWJigMAM9ak5p3rY+BOj80pzkaSL3VCY6XlPt47ANiFl2EPVK/No/rdmLXvPLQLM8k2lYtrwat6qlHTIKEogwHHs4bHDz8+EJhyssCKUgqw9nfKJ6YVzEHaLE4r7HqKssrITBg2KMudLldO4YwcdbIFKYcgYMJE3GKSQJjXJxAtzx54KnC2AH81W48oJooPnauRniSGgKQs6BEq/EQ0PaJRPPgbuoDtSeehR3k0DRnSFSTtA1lDzn8nHnnF8VqAl+Lo1K2oYXzm2ZAy5RNglK3/bYFVMI1XB8122iA7OFfhs2VmFl6H2bj8AqVMTRru8/pwgi/OM+9Z0+fPnnKxufYQ8FuUPcH/E/XT5IgGnMF42oRv4rpYENHWLKUbOT5whWXmm9e0c9bXtGFqAsb8gTBSNjUXJvPBifLH8lW+MP707OPtuPaT+CPuw9/3Kfwx/0T/HF39/fh5S6+tVmFortv0tQKK8jF5HbIHfHakx3L6ljnl9BF1+rMRq5lw2eUKe+RjSL5NLbyUYKmOD68JOfupT6OFbnkI8GUpkDYsGj3RW8c3PSixWxm7b34b7vW3/9ukRvoxedohzqpQzJ6KX0Pd3Z2vmfTHSa3rUQwCEM5wwNrQkSv+L2Uj6sW27UPg3zEp+GA2m9l2XSY3PqLfCpegFRIRyYIZLkEiCua4cJ1JFbSM7eBBdneKh5dD+nKfCwrMmbyG3tJCLDiUWXTYDYbWBRJASe9BaL2NXZwkeBtvuiMeCnaRi0o9Fd4D9GrL8F80WHTTx/tsOjlaJHO+MHvjNCoEsRO9KOhd8h8JPwYJnSY7YkfqI3KOgmsAhcUsR20Z/iY0O80u89mMZdDg5G9S+KTOohS/G+EhiPROBh3FslV6o+hdTYuQDWRGA/eocMUwJL0YFj4/3jIa9sd9/r9jvBBRvf9CU9lkAplByyf3X/W7/NkkusCKur+3pKs2jtYm7EFQDhqBJ/1/tj68ej1+9MjwwYMZO+kEwIz18YekHKbQ1BMwhQ4HUGecisLgsyRTNsHYRpxCJgDTYfCv+E+kFY8H7Cv+Skgx9v4Kqx+OZon+b2EgrRPfP35cnyM/AZbwJbAq1KfsuDD4YkG9MS/w7JnKVrL7YuX1PIbdLY4w5AXT/pF4Y+sYsis3f7gSX/wTH766+7u6zi99VNUrBvtofWN+v1yhnqMQ7wIot7CJFkKhvbxJXLd0Jz1pLziEm16f/NRCSrjOHTJvL52tYGe1a/2+auj14ef3p5JDTtApRAfnrU7bSmPirF815+31PUs2/x51lMJClFAwgkipARj+Jyn6gQluudZUK6Cw/fZKMeh/PnPEnU7INWgWi66akbixmEhn4AneReo7jC7j0ZxfA2r6+3WfU8no90nT/5U/RiO5skwGE3jIZt6DJV0mTUUluXiq0XGtlroUJFAf+sax3F1gcPs8v3PkN1+hkRZvH5taUFDH1BDgw9MNgkK2XbANxVHyBkQqq0KpgmSL0D3hmmQbW8qh7CAfA7nsAdDP6rM6rMtRn0dpFEw614nOS0Pc9575sfxPMiuiq+ylUnWzRbheDhezBPEcAUTPhSaXkRdNHzL9HrF5+x+Xnwt74M8mI97f4N1jfzZWMyNti2+YjOc/3eGJvcmezwCZQHK5O32+yfiveBixYen9N7onZ/k+L/s1F4fzv64OKQe1KnDD2eDAZDzMB6Ho8HgEx3dnQ98aHfeorGXtbO7c9BQvDgjP3HzXDhdRKP5mI9IgyHjiQUaIyiT1elEaNScTYGnKvgrYK2aS47LRZkL27qxMsPxG8EJRuI3QpFnycPB4N5Ajl/gbEfi7LaQ8B5SxKHq3CD3U2Z08W4wiCzmpYk6ME8dAjkHlvfqwPjkk5U6EMKrWH3jd3t7PWS+yxz2x48/HcDhBl1bFtz86jd1s9MBSW0UiBkW0OumEOev0+GZa+bvq1XJn3liyYhh1gd0OUGfGOt1GgSfQSCwXvBencf5eMv1W7cHtEJNC4v+cLoMJxW7zI625/7I1WTrwknvXfySTNhFeSGaWG0fuEUQFVFXiPGgyHH7wCo8kyw+ZDEG2a+i7uBXco1hmT/toABZeFyOwnH6QP1LoS9kF5YIBU3p1FxEI3LKQpbQ4Q+svVYASAEHSU78uqDdwjiE/JcGipEaiZ6ByAU/ViziBHmHRSSAw0fMeDpK9nXhSKkNB9b5UpvhVW+JQ14xuSfWIJOtdUAEHaA1AP7XK2wCbkIfmjf1Sivlm8VCkwJiNAxzs9JwgAUVXDfTZLoQ5Uv4oBvfkjFujVH2ASGCJ129e/iS32326jaMrYOx7tKd+bNc2FJn3Ty+DqLhNLhr/wB1SNz00IP/3GbRcWa7Nouj8NB5hn9hfdvFv+FHx1ZjvVAeLHt9p+RbTw1TT3q2wlXbsB7fShWywarcBC+NyrW20eygpm3S/CFvk7WXNsh1uR+Ngk44tgcTFTlNGIm7NokbHdkxe6AUBs5j+3NUY2MktaFDjsVAHTF3vy11mUNW6HqXcTxra+ii36XIaxTdLRG2srqILsAMVKs1E72BXjUMg8ysFdTC5F69MlwfwiwW4yWshZ92SzpX3fr3KGBTdA4yOKMIhHHqg3RFBJBE7a51GiwyFCx9VHbj3cHH98J6wI9Yz54uklz4Z3+vGeFQeMdZ4N8EFprZnBy+7B1/6Elstdi7Oc/90TRAKz9hhwjCnZ2RmcMvJ13pOjdUA5nYXfy3s6zbQKtihOWAA8Jy53YajtA+jKg6IdI4KxuKASfnnZeKXJQ1zfoiQ4XHUAMYGxOpXPItFQvjmCBwj2O9cywjRuhQhcom1d5q26fY7c90Kxmg0iWfGMBkzxw9LDm0RsvLjtHm5/k1fJ1kVe066lgRXP1djTFhPa2NngBoXN6galk7W3Vzw1LDpH3yzh8yNY/b5+bUmyvGusrzC6eyIuc4PKCqMK3JIucFVItjd25iOCOAAr08fnV4doi0+G/wJkDbxk6KUSovHlNva5dGTiCDw9gEWJZdC+TLsrNe1UuvbuZfFvNIGxd36K3Pynm2Jh0DL5miMIrBIkhQwugfKV8VYvCBKWzVXevn8EdHm31F2EX3hI9eq96tj0rgRDXH4VDjrPhnbeFlJ2P+ZbERtuX6Zl6xnaGrMfamQcYRisBxs9Y9iW8aMaws+TQqSx2QQAUEaxwHPKUECL3c8indgIylERLi9CWHGL0J02wKaEGyF/ksN1OjSwcbpTAk9TYey8uVvGuhsxGWbNzFQsivLZIuMNKk9+zapkdWjXXRxosj6Tcr2qN68u5Inlh385k22fr9sOfJy+FBGe/5ZnXtdbZ++VqmFeWoqJ5op3J1Pdl5Lvr54jlyBS+WotrqOTFwL55PWFlqAWYHqr+9F89liALkBu0ld2aFH6Qz8YsdHRE5/q2GiZK9F1PzvfUrK4B+1aIekKm4PPOSAE0jMPzxAV5kyzjL7w7PjGWALQ3r3TDd4gpe3v4+YFFMos8Iux4TuZC+PUyDHOZbJerDEDrkw+aKzly4HMmKZB2DV20IHoV/ANc8A++qluYycHKXLhDOJBODtKRt39ruOJgFeSBELPbhVn7TABLZbqAV3qRL4Rcq/qTVUcGah1GAjHc+LY7hJ/3yucUUEMmkoHdYQUPYCmDUa5Hcq81ZMU/69KGjdKX6llVLO6bVaFumh3Ko7L+l/uu7dHVAFkWMjni0qP0pYjUgmg8FDTZdY82BjGP2fKQoGtugjOf19SbwCA1M789KA1RmXQu7TwtP9HKYMsON8rx/wX6ipVBmfBu6iK6j+DayeQ6Y7Qc+f0PvwgleJ2+YgIqDZ9GFWi/PuYfxNQI/pRAm7fN+589+Z3Kx3Fu1/2kw0H46y6crx3YRgAtVjo0dPh+ISZl3r0DCT9q7Tj1J5LHCVGhDxYjzXA6YjfhSWDxzFBgORIP6LM2RBhGqGhCJDGwx3gwH40Hv8pSjLpEwAptOjytRG/+qdtJRvcCTjmI133DAN1KZ2uvX4YFrUbMen8ePP3eNv5we/MXrUGHE58qKpFgHw/9ld+9P3Tr/l/rVazatV8yXMX24FF6z03XhNwK9JJ0KuQhggebATBUbENFVBQPLKdOm5h4bmKihYnMoqzJyMn5FwkaOshCghaQWwqscoYhWQ8VXAtSs2FX+49CQiFFBHNGst18bfkvNZV2wrVoDrd8cfKuyxut9Ouo69cBdRlKmwiB08Aq6eK8Mvcdd90/Pvzv/PO5eOEADP4+Xu+6T1eeus4S/+Qe87tEjkMV/sl1quWZXCcWkp1qS5k49DIR83r9oNYR3qbMBk/bD9c5rtY41zG0eT1hFgwKuDNSFUmBhk1uEnptzrDm6GAfZD+RGcvARquq67qoQZojrEjwgl3z/wO4KJBSAHrCna08bZe1JLCKcsBulE01aKExFMQyKJzWD9ovnAEitrU1KcpQGeEtKDh0+SPkCP6JMMROAkJkPYxIgVBtChGDFsVckYqANYghvVGKtuFSxSt0oM8k0Eub9QWUGRLENEwByMbzkfq7sijS1xUxwdLY5LRoRPHSYQTVGCHtifkk/5/4dPt6MkkUmv4lf8ImCbbikYEf9aRBNUXE8ZhW8IuyviDO0/nrytmv9Ksv8iiNjr6mOuCJHc518EdE1HutNMNkDpbehyJJCR5nMBDS5XviS9F5ShKO8OTDBbGWO3A5hNDmnB3OKaZfFnHMHmyEzIQoCScGeCqYFhgn9Cbwwpn/wTIlj5KLz1Eep6EucSeIovnk7z+fBXPygNZlp078jeywnQfca/pDGSA+4n+g5eRuEV1NAwUWEcfyERT5dp5OXeHh1FbDvE3qLowMx+gdEnNUHmZGbQNnPd3VfUhrLZOdzZFnPxU9AKnQmyF4sOSIA2nmqRXacR09390B8F2We92StIjxhGCcZe/i5RVh6FVj/+D08vT0+OcZw7H1MHHBgzS/X1Tj5saixT5kGdKtVZSArzYCh9QF/kUansK3Y0RC/YTSdF0t8glGUXu+YDPZlM6TL+zwQoLBYEcdLAS1K7FSMaQGsQCP7OT+8sB/b4m6RCjiPbdif4pOGGHjF20nQ7I5PDFRjUKA18oTT4pmyyohvC/QNY2LAFphKvnwfoMVT2aCHSUcAS+B4y1BvEsbAFuz2iaQUYDSEiKTHZ2l1gR7yutISo5+pU3JPM0+y60vcaI92956W/e5w88HaXMJM3IbjfPoC6CiHwfJhK6O3sL28vgTKeLlIs5x+PNojAqriZW0q2CuAy60LlNOrHnetovvQrYEsh38Xttg68QUOk4o+Nt9Wbpafs1Qt6DgqUl9AEaFYo0s3oVXDt7AQcXqPfkMwipPwR/vFsiDhK1oo+E5FR4sUz42T+hrFGQC1jKJUGSmDRYNCWurZzPTYligJM2gcFyuAqogJAMTnF0tBQ/C2+XkMRAVHaKE45tl3PzwbPtu3ZWYxz/7y5Kn9Ynozh30GpV48v4zjnM+/6ZjWCQAgnElAec4Amj9KQvjgJ+EIv6sPLaZ54rTkwwdkrHwKksLV1Bax3jEjDB6iVBptlK14MskAo+1FPhLv4RxI0AoDvrzAYHlpfA/90F5iiTTArr4Q1hT0XbzCr+TjZHzkNwgeRheOuMP4Cz1yGQdQ02Zb/Nkjr23Yl+M0xOOLVaeo87ZFaQ70D0cCDEwMC917R34K+3cRzf1E4yjoetYm72ZCf+gWHi000TdjHzdIpp1mS6ZVsKJYY1NPR2MQU9Z1NfVvq31B1qLSl0z1JcP7JviKanKUG3Gti84saQOyPcPzEZDMSHFEgPF3toJqcEmia3F61cXudVl+JfmvywRPgBKNCNonmsnIN05ATPJ7rACndhbPAuMll75K/WQajjLJ+hZo11MIAI9EA14oYwvWfw759Tfh3DRejWDTsfHLCet3m1g0NgRmFbDOlnFEM9alSx4szBVTZUbERj5ZckN0dUO2HKwoLU4C1EL/LoyqfCgOoW+k0r5LygrtijxfUj4IpfZdYtwsKzWo7Gmj8C59lnmCdW/jGk34neHHRKHAOX0Bs900yTKCrlsTXE9aEdBCukTAdKa/2aKnemt4UJPNQESQQ65BxAo4QM7Vk+GjDizREXojQyHo8lt797nHVZ97IhfVusCIyElR8Avkonb/8z/+11JUosgBdgU0dILhAqO+Di7y8VW48BY9f1Ll+ikhy6RVzz0xJm6E4j6saYWIrmpmKaGsZHv0wxzIuguBJccWGbASDE/3RWYPqvp91xa32/aAFWKG1mmwSfHHFJOirMi0Hhidk7gakaFGGMVREI3UNAQTn9AIpSEwptRY10af/N56FdOcZ5hZIicNI+q70VuaNrc1CyZ5jPZvIlZThFY0QdqjMzoY9+Z+hIGUC3ubrjTt4fVAQkLxmNnwj52lmSoKpm7u34OgFs5mJNf5woyRDHMYVpwmsOmBTJE5ReJoeVEUPcOZcXkCXDniUuzMC7noEt7auBv2aTBhGQLEBxEMC+dB1SaZE83w4XTN25nDJDOKm8Y5KEWtLf15bBU2lrIJZ0OFrnVMiSlY9UuyzoICqcFgcKEzl41z59DxXhrgP/hijmsbXpK9Faz4ZTDBsFt0jqG/idgdWwQXdfQsLOreufBdQ8qoDK3QzsMwllqkM4zq1979wRG6gyzwmqKpq00yhAKACq+VISitfvUlbYXya4kZlQ+mnZY4UiVxxSAueuwZc/hcYxILLboytXBtvkC0O8KOhxyL2ZgHh+rUa9HpsJvMc8m0GgI+ADSvHGsCD2NdbENzY6Z6rKUWevEJxojPhUqcG9oqSnEhjp/46TUzPIBoeOjSlEpkCqObmAwN5HSgpim4wYs1UgMgcyjiRYu9hc7wswCxXovzVqz3Wap7IpdnmmHgXE/Q2oXTetmd17YLswEPl9q00xNCdlwgs6W1Xr2xC75jV7/RAH7Js5/uDZ7uD/r9gf3YHojNOrGVEWAK2/AymMW37b2nz5xBf+8OxGkkVsMiSv4TXYkjzwKv2dFeFdbw3JgMMg5uNDyuGh3rELVNYsJsjP2skUzFexobBLNdCmbFiNxWVxaTWiIfo6HVcUQRvOTZQOxgSHxdyGEgKcq+P2Kc9GVgfWsapAHfJ+BpxuaeRgQORbZxpXtkoEZXDnh/yzGokI2fo64RQ3Hk/nUgAnOIVBknRvzBNZIHKcPEHPCzNn5FPguhw7zQNLmOGDiO+nwOrhn9diCos63LBPK9bFsLeTvAfthax+hNUdKMgzaQDC+/FxoO+lLaQK68uBiibsEe6Ir/EmOkfsg7VdeWt5dDoyB/E0zWEMjWQEsdRJxZWvOBjIvIe4OsIBDIyphq7SAwkB8AxXNonPeUulEktqLJbEYzmWm2l3hiXpBS+XWykAGwliiti2RS4R3U5AK9aU4ppaefqIDAKTivX6ULT4PfUFFbqQs9b1Sl+HZLUCWjTV2o2iOb9bbOM1UFpDjoVBmVSGI+7hXpxMRVpZ/JmxpWVt8i2ZIRbdHt2bz1LHpo3JN/vYBCagVbUnPYg/KcaNiaTVSmTEjqycVqw40qCAm0zh3BA2DiF06eJpK3EMdA9jhEMnVTbSKfHNWJTgqyQdUg48GQSXZE6HGgFdiXqIbJhIs+KiG7rTWGdkKnue223sA21TSA11qs8vgmLeCRRTTNlaIJyUntgpVymfdpmySwEJrcts4XCJmqHP0LpajbqO6+nYZIVs+yA87GrCYimUppKEgiFc9jNiSMRtN5ngZBW8l/wv9cZCgo0loqEU9m2ciHBVqjwrQ4w4Ft2aS72cbuqKq50RUcVaXMb9XJNAlrFO5eWTxpEe93Haf0sRT51Ai26bhGxghtnOaBFeRz/24ezIXlELDGGhu0OiFhSHilVC1W+Yww6M2FmKeDckKTBq8tLAXDGuP1yx77YRWqQzrkFQKoudAQAHnR37j6poKutOi6uuyrtGVNq22upJkWAVcaafTvsdqkWBaLjWIVjllbY3ykULKLubHeVTtgXvsCPy9wrr7hqhv7XrKvxcJb32brHzTtexqUt2GVGigElWnAlpc8EqIRMhbmJfDfQYB+NJQRgarXaz01FuE7z4bFJbcn08DyvCxQfPstKTgBFY0YfROufHQxoXObPFuyUmzixTw7kBet1lUa32Kod7SYnJK5QiazSZKIp2UV6DZQrfUkCxmzbWnX7zpVBvWqQePfh4DVYa95lNTRuW3wFinderzVrwceSn6qy1SL+56G+9u3QTixnl0riJqUsb81WUN0wDukLI/RgoMDwAkMqHVrQC+sDtv1wxgwTV4jXRYKw6KRJI3xMrCuEfvnX07Y2qxsS/A5eieCFMjolGzWJzKxfo4wFPnAIpWd9djiy+fPEZs1023zQEZT+hwdSilbvRM+DUO0ph0WBil8oS1zJNMP0WEc6Ne5Osj5KNv/Npv+so2WnlnKyHYVSIOnF14RQTA7373wPO5yrcH00sZLcpTcsHD/ApCUjbPFmz14M/dH8meRCkK0tV9Wh1TMWHGttfDEYhbZwnIjdREmpZwDjvZ4c0LbdcalAmtEGZm3VzMtlXl8yEtaqWHIp62jEIGwnHd8YcxO8+cW4WML83ZujLgWNASDb8IYQicqWxIS6BgmFzhXpKKl+VtXPHNrd7VcBL65qcPm5nXgYrQOwrqjbh3w2mLd3hGN6YuGdRqoulyzwpB3yQBWVHOCxma1y4aJnr9i2RDNiSbT/QYdS/hK2vn/4xcNjqrw3wNdmGTDADxR6UHeKG0R9UOf8/pb6ppdQ/mcS1O9mWfl4Xtr50alo+DMBlrM1YFxJVA2Vyj733570dfo2PN1PLbKt9Bw3ztejOi+d8rJFUZBOBO+snRDrpwQUdk790Uk8ANLZa+iC2HKIYpogD4JcN6FeKkuDkNKuRFR8ALtovX3kd+l9UOzNPet5ffC/RYxpqwlxRTN0sxWUCSY2DBC1R9FKgYu1rVEZFacdrwbtij1Mgec1PJrmkpSaW9ZXXqNF3f1/BulnNJMKtFMV4Ci1EJiBSTSrNPTlwQIBrhegNik5lujDGkVaYzq92GFgf99tBC/jybiK/H2m2kivo2gUdoL31SsaNSXqEOOT5l65Gi0GNOQZI391Tc0v9L2LieZqsEL7aaxpKPS+ywH/NyAt0XaEoPmqzFwwmodFCfOyeNSziMY5iXaRXPgIKBdN8jwUuwVCiHXI09hjHmyIF1997fsnLVHARKvtdtK5UlST+u212ZrNLIR9bOhwHDLq2GtLM+zTAaitF4v1qwXFNPg1/gQmztqusjRdGidDLf/1KnN7acbZ/SdxuR+NeMT0d6XapDAnjI+2KsBe1Ftyr2+67S2a0ufy6+4pHpWvTXGOdfD0ZSNapiNsU17mY12MgV1Km/gC0lNmspqJ91X4PNvwZ6tLtq3vMf+euVOvVAx/HLlDynou1TycTxO1yoOhn5huX50F4wWeaBYzoqXOF18HnDUIBTX9FtWEJ9ucj/pifgZRcAYkdCOCJzwVsxjjuaKFjmYngxDtGHXM4sVJSJJaoh5aIDn47Iylqgw21HW8Il/j6Zqnh6BT02+HfCY7IHN8WPxt10kS7aB36LEPpk9WNo49VBSxcdHtUAKewaEupmQF0UvnAvXBgqMLjEy1BZdkK8Y9MoVkTjxMrFNGSQGtiPjSsEk8kWjacSPgXnnSV6QlB90hVAaXwYl9RNtOFJ0dUS3BFcgpmQ7X3sEvMkysMb7mWNzGxlPCJKwFaxaTIRjFu9ETXFWUbu2u1xJr/twbDvV2uPAx7jQgb5lHpOnZZ9ONzG4mpq3U0w3qVV7LmHVk2u2hRhKrLKXOwKFdgY7BQp1uNiOu6MQaGew3IHe7wz+OF6t7D/C4xr4266k2ZvNC1oiZFx9XXSiDXyOAACLCgirYsOItEH8QQ8ag9qTyiQJa027vpdkX65hkQHYqWBJ00hJ1+FLig9HE9qsVLxg1p2mXbSebXT3Fwrg4eWzfdKMFW3BWxG1TyiPauvC9NXUhbdb1MVFRvvTZ/tdADEOcCHbojNOV/wWMTbx7CXHQpus2EQpI7dJTdeq4EV/N4AXpdaCT0csMBiLgzBrUqSWkyKP1uIr6v7CmdcuoWYJISe2eX4wbljLFBMLng/gBOxfPGRLcKv1fRYncDls7abwh5WDVvYVy4wR3AYT69psi+XDRndoqhqj6SWN3imyXppmndwbBKAymvpwa99b2k0NjZhuYdF6FvgADCbgz9DOOEY/bRGuVbfiKtlfFTt5r0ioWoyp7LChfWptvSzmQLTYPEjtmMWC4+DGrXJXa1W1ZLzOHip6Km8ExUQc31/oWl2qUQkvYsuMAYQ8ni19QrLpLLjrflnE6FunNUBQnKoTgwBX5h4l8yhHJ8/cVhNGYv3S5H+PKeLYUA/DVGbBZDETWdIxw524rBnLCz/BRWborSJv/wSjSQ7IGtxaxpIchHDCEIpL+fbI7yAN5xgk+F/eHAofhEv0b8H4mAVGKdtOGQPMiClFDiqU4U2zdXfMzGqcb9oIUphlU6xdjmyVyZjZlQ2sarh2JykiZbv4Ht/hBdNHisD+E0zAz8H9S+QQUCcfxRqfq8BRhU9ZkP6Mcd2wToY+mZ6KTy+BvoyjCKb7TIo0/RpoExvzUP3zMkxWNkfyFjhilLwoY0y95kyyLNl0HTeqZ5ODkjUxwtdqbXg3M0eHWMqsSbci6gyspcLe1YH18eNPFEYFERc+tUXTZZ6o0iE4X3Z/gPNF13tu1S8jgKvWla7RFS3G6WhKqSnuA4qhyrmZMa9bupgF8vaH9Eb41qXEaq5Eb0otKH7RZ7xAJBduGf5P825m8Y73Z+f4A21Da0qxejnCyiuM/onNHlifXv+FnoB+o4sFJUMbS28Maq8+rJgKlFuTUlbvM2fVQ+5CDc3xiNsoBmOQp/bZfcJz7mq5ip1Ky1oey2iSD9Gm+L7NniPuN5nFWJBxP5zzrOGkGUk9WarGicqCGQeugvbGixElvs1knMoib6eaSu4nxzijRwdY69sgbasb3APOrMdX7fhUKVHYCuJQPHOKD6xilLWzDduYWy7UXDA5xDzidTRquGqjQmEwL1FRmvZAPUqAyhUVeM4MqKDnowTtocfJWtBUaRTPFHBMbgLAsV7FP1kNV0/UCO+LsYoPTnOLWYOFEtUrmtwSz4vl0DoxqFr28wzaA4GvtqrHiQYYOe0ChPQz1t+HiXwrEdu+mdsDgdKuzR46Is5WR1CDEBeBmhhHPvpECHML6dsMU4uVzpQLA2wKjIKZlnLkHqjj+ypWmI6sYay5P2Bvu/aqiXkrNDx4xnUoIzfuMQoYN4cNrV3PypRroQiI/cuHjx3iRbFjHUXqMCkp2zF1NX9cbTi02FNyH5O5i9OOSN2rDc9lqoVhgPgl9wkrk/9vZZDUliTqi/QqGOI6TJi4Z6UYkO/igqAUtFcGUQ8jk3BICn5AGQiZI1wk+v0zDGKexBgzSxGYJj62ajbb5IxDmk4ZPxZDF9c5mOfzxMNXXTTIHGYLwIg7CkDc5efHdheK2Krw9urShswUerR4PfOHGSXe5RjIPEBOnDmUgXHpgKONJE2fcE8Jmlas0QfMdgNrxKoSWv6QwpIJGwA4BUaotSIklFmXcv8KT091pnZbBO5dcMtwMpmeCkuQQzllt6A4TR1K/4RCPpmeYSvIR1CWJ2R/3qNfvgDTkjE8SBFLCSEJJKKR4fxN1iKATLcUzt00baCErTdxOKYEpVILjBCJF8HNhyw5qXwORN6MDJNRzUn8I9tb0thzbDmJj105g5tMyeTJJM6rzUfiP+jcEvfo2vFRD/KN2v5bHCHbeJUI3PSWOCu6EKjdk+j4m7FK6vzCKUTQ+mzGdzKV8cqcQ8+jyRvIpimjtcaRoQZCfRMRlbTvfF1idunCy8iMpi1ec8n1Hn8tqXQNaqyUWpqeNKg1ZG88Vfnk5DNT+s/ZGO4O6ndwLWedmyTjiOYovZkjGaBZpRzFqiUM2X9chLMxHYicVAt2VTYC9ARxhEiBxPWxFS3mQSqPDroqJouYPEiTGJ2ShSe8Su2sKQNKWobSjIoET9Sql8JOy4Lc6gSLFszSd9vlc8O8n9bOu/dDoBo7B6Rvs/qY0o1hYEWhGDbSollXQGStzpfQsv/tI30fCPJjG4AB6vD43eHLs+Nfjkzw31unHKiCD286/C4DP6VUIYsUg7R9WaAckl4HIABEwS1uMiyH83lJgUooC0ULZ4fcxv/Q1rrLhYJSOjfLv7227N73ilCfHL47fHP0qoMJs9vn54MsgZNjcHHx9z84PWt5lS0u273zz+efLy567s6O+4dd4sdh8aw/7K5sAEjhwDtphEF6MPetniBPhFbZ+QMmrKtPf9ca462SCnQypMzdw7fHH8+GQwHx3OpEACPZsS6wlqb1LpL/wWfM/rej0v/ZdQO0tV5UqgNj/ZDq1O9ikU+PXr5/9/L47dGrHUyTVoQBNEZkuwWWI8Xase2dGp2WiKNRVted2+Kejy/4CO0LfcWf+83KLUPdyjZqmNA7TunMugnI2jjIaA/nIkpFwuc+nrhYXlin9VCUx3DmdPYnfphqcGdxnFA8UhErDPdBoQTtVVSUl8A8zJHpk+qD7m8kZYobEca24cweIA2B8aP2/Gn/YtXS7rUknbORrNrmMtpEb6AuL4bIMdAGuaDDG13k+JRMBcFo20xJKpVR1azTgnIBmcKAlE3q+ulBk8D/muNm6CWT6PPBHmp5RDKVO0JIXNVFImNgAMu4ye56s+WMvOcqWV80WPOSQVLZpBfRmlxsqUsHdFXBtuubMwK26gOoxNFNkJJXyPsigkph+SEmTUv3hSqxOneUcK5PHHbQ1WSbjRHROPrZhnk8sLJ0pM2APq/wZcO0/khdIzOtysyuictmxjd6wAxCj7SgM6UZbLD5IKX0jeblVRW5ypTR+6oEJppTSzUfxL+9/PDpczv77Aw+Z48xOYRju6j6hTInpYQcda4qRRDlItODs3WuhyoQw/hNulS5WjAZhK7NHxbDsQ4jQ76uzhUUpGvuTPM2wEjG9lbzRkVFJuztHINqZjl7jNA/Z49gqh9RXpTuxeM1CVBqEgQJfSvM1AREsppJ3zKEgNk7OYnQrfOBdyF798DO8RzhWtJTPVJs0T8xSAIilho7CGfyqHaT1NvSfafb0pWP1n63L6Oe08C9BmTSzLDpw3P9lqMEK/PnySwg3Yh3cnR2SEStXUMHH9tdgCdzhca3FesytMEKYzijldURSj4F+IL2mUEnVD3dSkOrRmMkrYuzNtZEpXmDDOkQm/Kq4mAwqNEtRxGJMo48hK9XuiGcoczRAOtKnS3IiPQ1Ex1vXKJx7kGfOrx1ZGkmN9RjF74Sv4L/cg20s5dd75CiwqgmRufKIlRb/VDomQPiUBwTtMtvRiFpSImHgtd0PhTxcZJR7rURZG83+LPTa4/zR0xJdTiO82i3LxvQ6C28IhcI+ugCKEVXOW7cEM2ZASVJK0cbq9huzCev3WF2P7Mlu4lyq1dQds2ysob/F4YEIqK6NBkT20MsnYAANEXFWALunbjI/gackeAFQvj3mYu6H28c3nBeYfrs/vBsn1ifKYijZgl4dJ88o48wffANqmT6R2mFa0TvRySAtsrx9u0lvl2NC70TNUioUlucPq+mRXnsAxbfUA+Lrea21jPtI45glZl8t1JDsEup8EpnIzfc6u0tGL7NGp1tw6wAMmyKrHBgRKtb7ydExXFjVeGaNvci+G612NrQGqrbiwwQv889K07HXT2QnKNCHAy32/Ry+3m10RyyKoc4DygJ3QOZRFjOzFuuarMhzbM1eZDoJLp2bwyfaBC7Lg4I5vn1BU3lzYPYFc6NNbwO2acFAfE68Ae7EpqP6HDlZQFPCt01IBcRLpvtFm0SMO2n4QxZrKseha8o3euZTX8vQ8bamfUrt/UrqhxYosbMxHg1gFkpLJHkQN0vS9c6EVeeQ5lRwHGjR4R1TD5VB62OOWa9V4TLjKrFb+zhQrG8W0m8prSruvQlfEjUVCE/bRFa70v4YGPoLzpnBPWbTKCLGUHU+KKjWof9JRoNIo3J02qLV+uqr9kDW4Sv0/I6EbcMvEGVbS7IiO64scEpi0AjPhnxcUkN1taH22tTmphHT/hY1j/x2VxDJakQ8zFyznttvQOPJEzkYgq4MiwMn/kmd6M5FdTFziPqSXwpM6XQOnOpAia8LQhyOQoeBdgv4MP+QncEIhgDufdcmwXLgdp9rp1g4ty2LNFTX3BU0rOZN6ockbMy2zECcmqQq7H7zC5S2ozBZGdZTDBOafHXoLs7WVlvfkRrlfGOCPOHz5zjRwT644HVhQDE5qohQ/UX4jPNgXzSesiMpj1oZjxLkQsxZGFzBFL26xAx/uM5iBPKF2SgMWZsa8nnk/xeClyRZwPTYDPGe24OyaHijCdwEE8Df4YOKRqRP4VzXNkmjPGgzNgQl6YZUzsiRaeohpdxTrGP5nEecJUsmE06RAK7etjcnAO3Z2xshGn0pphcWphvkG8DKrx/OSlyfWGEJWjfitkAlmKdk+tj4o+ufZGCWrOlrOrGKlrplmn1KNXQ8XXJ7tBG9SBwmPBNRo7pyaOvVBKb4yQg9qAxmXqpDnE4w8LMd3AZx7N2babpclU8iIZwEG2oXSRULwNYE/7WLKihLSdHL8zGRJMywd7792/LrZRNjTQ7nbpgsEXtlYGcyJJoqCmDC3syEs1BHf8u48w4ejxkzC3Xnsz8K9fCRFesiIH3/mKWO1scvyG32UUbjzsCVCiXSbSmRsPHuxcbDsYmQ1OVf0t1T/ZOZ5A8HAbwHki8XXnZNXz5/uTD4RmGDhi++RGZfw6SJcriaVEp+/LDJy5I7JEoSfS2UpR4J4RrnIHlvaXpUJqyk2ixpSkTCdvmOsWKk6mA9Ha0MW4Fu3nSC22VGhcdZv9gvdSmYxfDZQPqxrv5r/XG3BjWZL2r5sFv9dNk84diqDCXxUi9ppHifZq4BaarLpESb607b+MUsPXFekfowv+32WD7a6YS9X/feA4lIpZwoyS1cuKwQlFPdNa1MdNZg7q+LmJ2usmd7sEO1tjKwX9ZTFbkYanIg1yO1eAhvf2vFZq8Pi74WlBbhwp/YNjz7UOeo2avydyrPh5zrZsb8qHSRlHZNLAtUhLDmO6V/WCRbxPYR0o6KLMuhJMG0Jp1Aysv2EEszFSmnzkZ9ESkCaoFsskqUwqmFfsy4MAd1yK7tcaI02v4BeP2oIbKf/12WItXRoD3bxBHoHyvrB/MbH9kb3vgN5krH3wbKrlNBHRjyxfpn5rUTm4lFZZbms4anjSpj1MuMAYdrN7F+WtUbXC0cgNJzIjkRoquurDkB41rA0IxKSYKpnw2bl6aKLht4s4PWk0BRQBiKehpjZXESz9ir6SIcrLLUEYUJQdDc83u9Xu62XhY0QPCy8JgAzpaLQEvK0FlKH0sl91gx3HGUcSUlYxMo8C1tN5h2sQSpsLegbe2C300gjdJ1y9ppjaxRZJZHIzIMWu76i0OQL3ddVQ1MpcRc8K2H3JMzm9PsfgbMywW2608+EqEfzECbR3UK8aLYlgPTOn4pEoG9BQqwe1XJEIod7+CRsSfI1LXDEwVFgNTq1d1R6wklKzmk1TRQNxLTr+g0yPcfiaBCm4dkZBBK6ERLPxeTcDga933Zb/NYF4FIUKQWvnSB1G5IFvB7eZThBT1g/o4w8r6qI44dYB01e26GkGVrK6FHqnIzKidf/q1Y1NbuggM/aZYvw39bgyN3NRHVs3htQXmq9P6aNtGo8LpqGi3GlG5ZcrOFNHZLG+GeTbhA+/TIVP9LQ/1aeIVehU8Lqwr/c2TC+VgyC909QzMD32ynce7F0Km5RdKphV2m+jTp6d7oWCZCfCZIpyDH0ne0wLuARVYbPLNbt7FqaP5ZjE3Sq5Xxx+sm9BHD/Aaj+8tWHS8U4fJu2In7y2j4mtbYgOLepW4JS60wU8wTIRzIHXm2zQl6hWer+wFM02Ex2uYYCXDkqlAJOHx8o1wqYQ6hcMU4Y8jEEh7XcKivb1vjor/j2GJ4WH0uyNKpbUqrogim9GFVw09TSWUNfPagED6/aSif0He4TMSIOvpCBtguBryNR1YIlrnYNso7NiJ0pKuU4ej++W9J8knmTQoVfr+Rfn0xrJ4Fs2BkHX5Nr879++KeWzKUlQYxCJfyckAC7eKkx/hLLIdR1ziO1s0q52F1fjV37y1rrpKLQ+0ms/iGzY+ShbV6a3LASQMPhbBZoD1Eyej724JpH4+6vN7NIH93vr5lxMZv0EkUQ7STpbfz9DZCC/PRGBWaD0jvxVMdx5c+aN77QN5h1J+TfI+I/dPgNgBXidbjEZBlh2UmsXLxldhNsL8vtKtDM5zvKyVViuz4CaYWfkIJGSf/LVFUD0QILs1c9NlXzuUjdo2d32gcVVGosY65rRmWz8rb2txnai93pO7XXu3j+8wNIr+8umF0UFcda+sdTNxoo5YAHPl6nF4C9h05Wx7KExCXwtcfyNw3fmtg0QmgN7ZUTjCkPqeiNajXUdsR/GYQ+R0D4rXLo+ATmSvgI1l+DxWPw90DreSd0KkndiaZDcMu8LQbB6aCAsukaG2m3pmBj1XwjqxiYJXbstZheM7r8TuIKcjGJ0Ko3RgHsKFi5y4Ph3fDS6c0pmY3P9OyiaZrgBkyfr926w7RaFUIVejTmlrfZLKNbJBo/SR8oBYjX5XUtW1VTqvAyoqT4NmK1KpaaiFutaWVKu7nbVWpX5tECyc/OYw1Wr8rhieaw7AWZOlu9FFSuzy9V5SHGUtjoCp1I3oNLO9h9sSauGRzWiVpk1eZaKV6RnFKmz6qCOh2XPreWOtOt3dpqjMZVj/kDTmBxvzl8POP6jmJw9utfTk8MPMTn5gJh/XCjtN+bcRRikDucJShzNwq9/8s5yEXKCyo3B6TYbuPW8MJyftMnH3unfOxoQXHnRFvTKvd9Qv9b0c8trcRmYxI4p2ebGNC2CY8jU3RXs1+cS+Rgl7sOZ0Yx9cWcD0o90ovJkKxrkJq+xayrXdhiPJaTUGavsUFclckNizKWB4GQLvci8Z2YG1FE8UX5TCv5HhICGd4PkMr1UO3AWbIb2CXmRB91CEFf6AvyhK15Vn3yTZKJ+JEyVbXHp+glE1hvBItQASXqTB0Twf266069KcdxMPilIVLt8W6Z1xNRmUDGfcZryseR9ndW+F3ROxhUBaS43XlSfbpweUZwuoB1RQqaprvwptIhnkY7QSUpsC6gM0u3GyaLHr4GlRm9OrrFjG06OTw+N3r45Om0BqUckfsAYYGvThbQn6/4B2Squ6eR23WLmm3tGB29i3hkqs519fi2cp6VIdLJJp4X7gVxdTd5H9itgMrlxodWRqhix09YaCMmYcD9Ihxjdq19ywCMDIJzPUAQf5aFet8aisjB6bdeOM/0WzPAYDpwo90NFCT8UpCHwmvRH4XHGInZU6wyOr6wwbNSsPLa4kTJg3gRXzVANWyLKlMdaPTbl4l6Brm0S2oEkpJdC4NxrgiGsnhrDVrZOCXXvrVN8K42TNVDRfOBXNkB86wBvSh+EQ4A2HJBMNhazFZ0jr/wKDrBRX'
VPSCTL_SHA256='7793b32d2fcb603b21f4c37d13ac543f5e5a2677e454367edf39049e578cd14e'

say() { printf '[RGNODES-NODE] %s\n' "$*"; }
die() { printf '[RGNODES-NODE] ERROR: %s\n' "$*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die 'Run as root: sudo bash node.sh --api-key=KEY --port=PORT'
command -v python3 >/dev/null 2>&1 || die 'Python 3 is required.'
python3 - <<'PYVER' || die 'Python 3.10 or newer is required.'
import sys
raise SystemExit(0 if sys.version_info >= (3,10) else 1)
PYVER

API_KEY=''
PORT='18443'
HOST=''
KEY_SUPPLIED=0
KEY_GENERATED=0
FORCE_PROMPT_KEY=0
while (($#)); do
  case "$1" in
    --api-key|--api_key) (($# >= 2)) || die "$1 requires a value"; API_KEY="$2"; KEY_SUPPLIED=1; shift 2;;
    --api-key=*) API_KEY="${1#*=}"; KEY_SUPPLIED=1; shift;;
    --api_key=*) API_KEY="${1#*=}"; KEY_SUPPLIED=1; shift;;
    --prompt-api-key) FORCE_PROMPT_KEY=1; shift;;
    --port) (($# >= 2)) || die '--port requires a value'; PORT="$2"; shift 2;;
    --port=*) PORT="${1#*=}"; shift;;
    --host) (($# >= 2)) || die '--host requires a value'; HOST="$2"; shift 2;;
    --host=*) HOST="${1#*=}"; shift;;
    -h|--help) printf 'Usage: sudo bash node.sh [--api-key KEY] [--prompt-api-key] [--port 18443] [--host 127.0.0.1]\n'; exit 0;;
    *) die "Unknown option: $1";;
  esac
done
[[ "$PORT" =~ ^[0-9]+$ ]] && ((PORT >= 1 && PORT <= 65535)) || die 'Port must be an integer from 1 to 65535.'

export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a APT_LISTCHANGES_FRONTEND=none
command -v apt-get >/dev/null 2>&1 || die 'Debian/Ubuntu apt-get is required.'
say 'Installing KVM/QEMU/libvirt and node-agent runtime packages.'
apt-get update
apt-get install -y sudo net-tools cpu-checker python3 ca-certificates curl iproute2 iputils-ping openssl \
  qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients \
  cloud-image-utils openssh-server openssh-client sshpass acl ufw
for unit in libvirtd.service virtqemud.service virtlogd.service virtlockd.service; do
  systemctl enable --now "$unit" >/dev/null 2>&1 || true
done
command -v virsh >/dev/null 2>&1 || die 'virsh is unavailable after package installation.'
command -v qemu-img >/dev/null 2>&1 || die 'qemu-img is unavailable after package installation.'
[[ -e /dev/kvm ]] || die '/dev/kvm is missing. Enable hardware/nested virtualization at your VPS provider before using this node.'
virsh -c qemu:///system list --all >/dev/null 2>&1 || die 'libvirt qemu:///system did not become ready; inspect libvirtd/virtqemud.'

APP=/opt/rgnodes-node-agent
ENV_DIR=/etc/rgnodes
ENV_FILE="$ENV_DIR/node-agent.env"
CONTROLLER=/usr/local/sbin/vpsctl
UNIT=/etc/systemd/system/rgnodes-node-agent.service
install -d -m 0755 "$APP" "$ENV_DIR" /var/lib/rgnodes-vps/images /var/lib/rgnodes-vps/disks /var/lib/rgnodes-vps/seeds /var/lib/rgnodes-vps/meta /var/lib/rgnodes-vps/secrets
chmod 0700 /var/lib/rgnodes-vps /var/lib/rgnodes-vps/secrets

if (( FORCE_PROMPT_KEY )) && [[ ! -t 0 ]]; then
  die '--prompt-api-key requires an interactive terminal so the new secret can be entered without being echoed.'
fi
if (( FORCE_PROMPT_KEY )); then
  API_KEY=''
elif [[ -z "$API_KEY" ]]; then
  API_KEY="$(python3 - "$ENV_FILE" <<'PYKEY'
import sys
from pathlib import Path
p=Path(sys.argv[1])
if p.exists():
    for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
        s=line.strip()
        if s and not s.startswith('#') and '=' in s:
            k,v=s.split('=',1)
            if k.strip()=='RGNODES_NODE_API_KEY':
                v=v.strip().strip('"').strip("'")
                if len(v)>=32: print(v); raise SystemExit(0)
print('')
PYKEY
)"
fi
if [[ -z "$API_KEY" && -t 0 ]]; then
  read -r -s -p 'Enter the node API key from the bot DM (input hidden): ' API_KEY
  printf '\n'
  [[ -z "$API_KEY" ]] || KEY_SUPPLIED=1
fi
if [[ -z "$API_KEY" ]]; then
  API_KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
  KEY_GENERATED=1
fi
[[ ${#API_KEY} -ge 32 && "$API_KEY" != *[$'\r\n '$'\t']* ]] || die 'API key must be at least 32 non-whitespace characters.'

if [[ -z "$HOST" ]]; then
  HOST="$(python3 - "$ENV_FILE" <<'PYHOST'
import sys
from pathlib import Path
p=Path(sys.argv[1])
if p.exists():
    for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
        s=line.strip()
        if s and not s.startswith('#') and '=' in s:
            k,v=s.split('=',1)
            if k.strip()=='RGNODES_AGENT_HOST': print(v.strip().strip('"').strip("'")); raise SystemExit(0)
print('127.0.0.1')
PYHOST
)"
fi
[[ "$HOST" =~ ^[A-Za-z0-9.:_-]+$ ]] || die 'Invalid bind host. Use 127.0.0.1, ::1, or an intentional interface address.'

# Decompress to private temporary files, check exact digests, then atomically install.
python3 - "$NODE_AGENT_ZLIB_B64" "$NODE_AGENT_SHA256" "$VPSCTL_ZLIB_B64" "$VPSCTL_SHA256" "$APP/node-agent.py" "$CONTROLLER" <<'PYEMBED'
import base64,hashlib,os,sys,tempfile,zlib
agent_b64,agent_hash,ctl_b64,ctl_hash,agent_out,ctl_out=sys.argv[1:]
for encoded,expected,target in ((agent_b64,agent_hash,agent_out),(ctl_b64,ctl_hash,ctl_out)):
    data=zlib.decompress(base64.b64decode(encoded,validate=True))
    if hashlib.sha256(data).hexdigest()!=expected:
        raise SystemExit(f'Embedded payload integrity check failed for {target}')
    if target.endswith('node-agent.py'):
        compile(data.decode('utf-8'),'node-agent.py','exec')
    else:
        text=data.decode('utf-8')
        compile(text,'vpsctl','exec')
        if not all(x in text for x in ('KVM/QEMU/libvirt only','def compat(','virsh')):
            raise SystemExit('Embedded controller is not the expected KVM controller')
    directory=os.path.dirname(target)
    fd,tmp=tempfile.mkstemp(prefix='.rgnodes-embed-',dir=directory)
    try:
        with os.fdopen(fd,'wb') as f: f.write(data); f.flush(); os.fsync(f.fileno())
        os.chmod(tmp,0o755); os.replace(tmp,target)
    finally:
        try: os.unlink(tmp)
        except FileNotFoundError: pass
print('Embedded node-agent and KVM controller hashes/syntax verified.')
PYEMBED

# Detect the provider uplink where possible; public IPv4 routing still depends on provider setup.
UPLINK="$(ip -4 route show default 2>/dev/null | awk '/^default/ {for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}' || true)"

# Atomically write credentials and fill missing network defaults without replacing custom settings.
python3 - "$ENV_FILE" "$API_KEY" "$HOST" "$PORT" "$CONTROLLER" "$UPLINK" <<'PYENV'
import os,sys,tempfile
from pathlib import Path
path=Path(sys.argv[1]); api_key,host,port,controller,uplink=sys.argv[2:]
forced={
    'RGNODES_NODE_API_KEY':api_key,
    'RGNODES_AGENT_HOST':host,
    'RGNODES_AGENT_PORT':port,
    'RGNODES_VPSCTL_PATH':controller,
}
defaults={
    'RGNODES_VPS_ROOT':'/var/lib/rgnodes-vps',
    'KVM_NETWORK_MODE':'direct',
    'PUBLIC_PARENT_INTERFACE':uplink.strip(),
    'PUBLIC_BRIDGE_NAME':'',
    'REAL_PUBLIC_IPV4_REQUIRED':'true',
    'PUBLIC_IPV4_POOL_CIDR':'',
    'PUBLIC_IPV4_GATEWAY':'',
    'PUBLIC_IPV4_DNS':'1.1.1.1,8.8.8.8',
    'HOST_RAM_RESERVE_GB':'2',
    'HOST_CPU_RESERVE':'1',
    'HOST_VCPU_OVERCOMMIT_RATIO':'1.5',
    'HOST_DISK_RESERVE_GB':'10',
    'MAX_DEPLOY_RAM_SHARE':'0.80',
    'HOST_CPU_MAX_DEPLOY_PCT':'85',
    'MIN_HOST_RAM_FREE_PCT_DEPLOY':'18',
    'MAX_VPS_RAM_GB':'8',
    'MAX_VPS_CPU':'8',
    'MIN_VPS_DISK_GB':'10',
    'MAX_VPS_DISK_GB':'100',
    'INITIAL_VPS_RAM_GB':'1',
    'INITIAL_VPS_CPU':'1',
    'INITIAL_VPS_DISK_GB':'10',
}
existing=path.read_text(encoding='utf-8',errors='replace').splitlines() if path.exists() else []
out=[]; seen=set()
def unquote(value):
    value=value.strip()
    if len(value)>=2 and value[0]==value[-1] and value[0] in '"\'': value=value[1:-1]
    return value
for line in existing:
    item=line.strip()
    if item and not item.startswith('#') and '=' in item:
        key,value=item.split('=',1); key=key.strip()
        if key in forced or key in defaults:
            if key in seen: continue
            seen.add(key)
            if key in forced: value=forced[key]
            elif not unquote(value): value=defaults[key]
            else: value=unquote(value)
            out.append(f'{key}={value}')
            continue
    out.append(line)
for mapping in (forced,defaults):
    for key,value in mapping.items():
        if key not in seen: out.append(f'{key}={value}'); seen.add(key)
fd,tmp=tempfile.mkstemp(prefix='.node-agent-env-',dir=str(path.parent))
try:
    with os.fdopen(fd,'w',encoding='utf-8') as f: f.write('\n'.join(out)+'\n'); f.flush(); os.fsync(f.fileno())
    os.chmod(tmp,0o600); os.replace(tmp,path)
finally:
    try: os.unlink(tmp)
    except FileNotFoundError: pass
PYENV

cat > "$UNIT" <<EOF
[Unit]
Description=RGNODES Remote KVM VPS Node Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$APP
EnvironmentFile=$ENV_FILE
Environment=PYTHONUNBUFFERED=1
ExecStart=/usr/bin/python3 $APP/node-agent.py
Restart=on-failure
RestartSec=3
StartLimitIntervalSec=300
StartLimitBurst=5
LimitNOFILE=65535
UMask=0077

[Install]
WantedBy=multi-user.target
EOF
chmod 0644 "$UNIT"
python3 -m py_compile "$APP/node-agent.py" "$CONTROLLER"
systemctl daemon-reload
systemctl enable --now rgnodes-node-agent.service
systemctl is-active --quiet rgnodes-node-agent.service || { journalctl -u rgnodes-node-agent.service -n 60 --no-pager || true; die 'node-agent service did not start'; }

# Do not auto-open firewall ports or bind publicly; plain HTTP is not safe on an exposed interface.
if [[ "$HOST" != '127.0.0.1' && "$HOST" != '::1' ]]; then
  say 'WARNING: the agent is bound to a non-loopback address. Restrict firewall access to a trusted VPN/TLS proxy; never expose plain HTTP to the Internet.'
fi
if (( KEY_GENERATED == 1 )); then
  printf '\nGenerated node API key (save it securely and enter the same key in the bot node settings):\n%s\n' "$API_KEY"
else
  say 'Node API key configured; secret is stored in /etc/rgnodes/node-agent.env with mode 0600.'
fi
say 'Remote KVM node agent is active. This host must have provider-routed public IPv4 if guests need direct public IPv4 addresses.'
